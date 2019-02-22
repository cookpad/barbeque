class CreateBarbequeRetryConfigs < ActiveRecord::Migration[5.2]
  def change
    create_table :barbeque_retry_configs, options: 'ENGINE=InnoDB ROW_FORMAT=dynamic DEFAULT CHARSET=utf8mb4' do |t|
      t.integer :job_definition_id, null: false
      t.integer :retry_limit, null: false, default: 3
      t.float :base_delay, null: false, default: '0.3'
      t.integer :max_delay
      t.boolean :jitter, null: false, default: true
      t.timestamps

      t.index [:job_definition_id], unique: true
    end
  end
end
