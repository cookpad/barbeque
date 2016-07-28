class AddFinishedAtToJobExecutions < ActiveRecord::Migration[5.0]
  def change
    add_column :job_executions, :finished_at, :datetime
  end
end
