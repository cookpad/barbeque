class AddIndexToJobExecutionStatus < ActiveRecord::Migration[5.0]
  def change
    add_index :barbeque_job_executions, :status
    add_index :barbeque_job_retries, :status
  end
end
