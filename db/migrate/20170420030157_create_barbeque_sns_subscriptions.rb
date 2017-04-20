class CreateBarbequeSnsSubscriptions < ActiveRecord::Migration[5.0]
  def change
    create_table :barbeque_sns_subscriptions do |t|
      t.string :topic_arn, null: false
      t.integer :job_queue_id, null: false
      t.integer :job_definition_id, null: false

      t.timestamps
    end
  end
end
