class CreateSlackNotifications < ActiveRecord::Migration[5.0]
  def change
    create_table :slack_notifications, options: 'ENGINE=InnoDB ROW_FORMAT=dynamic DEFAULT CHARSET=utf8mb4' do |t|
      t.integer :job_definition_id
      t.string :channel, null: false
      t.boolean :notify_success, default: false, null: false
      t.string :failure_notification_text

      t.timestamps
    end
  end
end
