class CreateJobRetries < ActiveRecord::Migration[5.0]
  def change
    create_table :job_retries, options: 'ENGINE=InnoDB ROW_FORMAT=dynamic DEFAULT CHARSET=utf8mb4' do |t|
      t.string :message_id, null: false
      t.integer :job_execution_id, null: false
      t.integer :status, null: false, default: 0
      t.datetime :finished_at

      t.timestamps
    end
    add_index :job_retries, [:message_id], unique: true
  end
end
