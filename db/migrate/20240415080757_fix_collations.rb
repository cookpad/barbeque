# In MySQL 8.0, the default collation for utf8mb4 is changed to utf8mb4_0900_ai_ci.
# The column collations are utf8mb4_0900_ai_ci after we ran migrations prior to this
# on MySQL 8.0 because we did not specify collation in create_table (thus the default is used).
# This happens on testing/development but we want to keep utf8mb4_general_ci.
#
# Note that running this should not affect the actual schema and data
# unless you've ran prior migrations on MySQL 8.0.
class FixCollations < ActiveRecord::Migration[6.1]
  def change
    reversible do |direction|
      direction.up do
        # alter column collations and default collation of every tables defined to utf8mb4_general_ci
        execute 'ALTER TABLE barbeque_apps CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci'
        execute 'ALTER TABLE barbeque_docker_containers CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci'
        execute 'ALTER TABLE barbeque_ecs_hako_tasks CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci'
        execute 'ALTER TABLE barbeque_job_executions CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci'
        execute 'ALTER TABLE barbeque_job_queues CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci'
        execute 'ALTER TABLE barbeque_job_retries CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci'
        execute 'ALTER TABLE barbeque_retry_configs CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci'
        execute 'ALTER TABLE barbeque_slack_notifications CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci'
        execute 'ALTER TABLE barbeque_sns_subscriptions CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci'

        # barbeque_job_definitions contains a column with explicitly specified collation
        execute 'ALTER TABLE barbeque_job_definitions DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci'
        change_column :barbeque_job_definitions, :command, :string, collation: 'utf8mb4_general_ci'
        change_column :barbeque_job_definitions, :description, :text, collation: 'utf8mb4_general_ci'
      end

      direction.down do
        raise ActiveRecord::IrreversibleMigration
      end
    end
  end
end
