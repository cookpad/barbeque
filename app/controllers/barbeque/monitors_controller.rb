class Barbeque::MonitorsController < Barbeque::ApplicationController
  def index
    hour_sql = "date_format(#{Barbeque::JobExecution.table_name}.created_at, '%Y-%m-%d %H:00:00')"
    now = Time.zone.now
    from = 6.hours.ago(now.beginning_of_hour)
    rows = Barbeque::JobExecution.find_by_sql([<<SQL.strip_heredoc, from, now]).map(&:attributes)
    select
      t.date_hour
      , app.id as app_id
      , app.name as app_name
      , def.id as job_id
      , def.job as job_name
      , t.cnt
    from
      (
        select
          date_format(e.created_at, '%Y-%m-%d %H:00:00') as date_hour
          , e.job_definition_id
          , count(1) as cnt
        from #{Barbeque::JobExecution.table_name} e
        where
          e.created_at between ? and ?
        group by
          date_hour
          , e.job_definition_id
      ) t
      inner join #{Barbeque::JobDefinition.table_name} def on def.id = t.job_definition_id
      inner join #{Barbeque::App.table_name} app on app.id = def.app_id
SQL

    jobs = {}
    rows.each do |row|
      job = {
        app_id: row.fetch('app_id'),
        app_name: row.fetch('app_name'),
        job_id: row.fetch('job_id'),
        job_name: row.fetch('job_name'),
      }
      jobs[job[:job_id]] = job
    end

    @recently_processed_jobs = {}
    t = from
    while t < now
      @recently_processed_jobs[t] = {}
      jobs.each do |job_id, job|
        @recently_processed_jobs[t][job_id] = job.merge(count: 0)
      end
      t += 1.hour
    end

    rows.each do |row|
      date_hour = Time.zone.parse("#{row.fetch('date_hour')} UTC")
      job_id = row.fetch('job_id')
      @recently_processed_jobs[date_hour][job_id] = jobs[job_id].merge(count: row.fetch('cnt'))
    end
  end
end
