class AddJobQueueIdToJobExecutions < ActiveRecord::Migration[5.0]
  def change
    add_column :job_executions, :job_queue_id, :integer
  end
end
