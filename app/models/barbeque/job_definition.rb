class Barbeque::JobDefinition < Barbeque::ApplicationRecord
  belongs_to :app
  has_many :job_executions, dependent: :destroy
  has_one :slack_notification, dependent: :destroy

  validates :job, uniqueness: { scope: :app_id }

  attr_readonly :app_id
  attr_readonly :job

  serialize :command, Array

  accepts_nested_attributes_for :slack_notification, allow_destroy: true

  DATE_HOUR_SQL = 'date_format(created_at, "%Y-%m-%d %H:00:00")'

  def execution_stats(from, to)
    job_executions.where(created_at: from .. to).group(DATE_HOUR_SQL).order(DATE_HOUR_SQL).pluck("#{DATE_HOUR_SQL}, count(1), avg(timestampdiff(second, created_at, finished_at))").map do |date_hour, count, avg_time|
      {
        date_hour: Time.zone.parse("#{date_hour} UTC"),
        count: count,
        avg_time: avg_time,
      }
    end
  end
end
