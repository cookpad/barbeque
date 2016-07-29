class CreateJobDefinitions < ActiveRecord::Migration[5.0]
  def change
    create_table :job_definitions, options: 'ENGINE=InnoDB ROW_FORMAT=dynamic DEFAULT CHARSET=utf8mb4' do |t|
      t.string :job, null: false
      t.integer :app_id, null: false
      t.string :command, null: false
      t.text :description

      t.timestamps
    end
    add_index :job_definitions, [:job, :app_id], unique: true
  end
end
