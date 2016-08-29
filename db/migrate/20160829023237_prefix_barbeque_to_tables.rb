class PrefixBarbequeToTables < ActiveRecord::Migration[5.0]
  def change
    rename_table :apps, :barbeque_apps
    rename_table :job_definitions, :barbeque_job_definitions
    rename_table :job_executions, :barbeque_job_executions
    rename_table :job_queues, :barbeque_job_queues
    rename_table :job_retries, :barbeque_job_retries
    rename_table :slack_notifications, :barbeque_slack_notifications
  end
end
