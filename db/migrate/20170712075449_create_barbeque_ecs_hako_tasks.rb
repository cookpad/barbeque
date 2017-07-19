class CreateBarbequeEcsHakoTasks < ActiveRecord::Migration[5.0]
  def change
    create_table :barbeque_ecs_hako_tasks, options: 'ENGINE=InnoDB ROW_FORMAT=dynamic DEFAULT CHARSET=utf8mb4' do |t|
      t.string :message_id, null: false
      t.string :cluster, null: false
      t.string :task_arn, null: false

      t.timestamps

      t.index ['message_id'], unique: true
    end
  end
end
