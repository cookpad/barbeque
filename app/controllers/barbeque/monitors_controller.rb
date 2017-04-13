class Barbeque::MonitorsController < Barbeque::ApplicationController
  def index
    hour_sql = "date_format(#{Barbeque::JobExecution.table_name}.created_at, '%Y-%m-%d %H:00:00')"
    now = Time.zone.now
    from = 6.hours.ago(now.beginning_of_hour)
    rows = Barbeque::JobExecution.
      joins(job_definition: :app).
      where(created_at: from .. now).
      group("#{hour_sql}, #{Barbeque::JobDefinition.table_name}.id").
      pluck("#{hour_sql}, #{Barbeque::App.table_name}.id, #{Barbeque::App.table_name}.name, #{Barbeque::JobDefinition.table_name}.id, #{Barbeque::JobDefinition.table_name}.job, count(1)")

    jobs = {}
    rows.each do |_, app_id, app_name, job_id, job_name, _|
      job = {
        app_id: app_id,
        app_name: app_name,
        job_id: job_id,
        job_name: job_name,
      }
      jobs[job_id] = job
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

    rows.each do |date_hour, _, _, job_id, _, count|
      date_hour = Time.zone.parse("#{date_hour} UTC")
      @recently_processed_jobs[date_hour][job_id] = jobs[job_id].merge(count: count)
    end
  end
end
