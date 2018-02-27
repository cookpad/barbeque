class AddIndexToJobExecutionJobQueueIdAndStatus < ActiveRecord::Migration[5.1]
  def change
    add_index :barbeque_job_executions, [:job_queue_id, :status]
  end
end
