class AddIndexToBarbequeJobExecutionsCreatedAt < ActiveRecord::Migration[5.1]
  def change
    add_index :barbeque_job_executions, :created_at
  end
end
