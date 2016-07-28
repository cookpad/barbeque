class CreateJobQueues < ActiveRecord::Migration[5.0]
  def change
    create_table :job_queues, options: 'ENGINE=InnoDB ROW_FORMAT=dynamic DEFAULT CHARSET=utf8mb4' do |t|
      t.string :name, null: false
      t.text :description
      t.string :queue_url, null: false

      t.timestamps
    end
    add_index :job_queues, [:name], unique: true
  end
end
