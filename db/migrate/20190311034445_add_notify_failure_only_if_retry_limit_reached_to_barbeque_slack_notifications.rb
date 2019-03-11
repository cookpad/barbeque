class AddNotifyFailureOnlyIfRetryLimitReachedToBarbequeSlackNotifications < ActiveRecord::Migration[5.2]
  def change
    add_column :barbeque_slack_notifications, :notify_failure_only_if_retry_limit_reached, :boolean, default: false, null: false
  end
end
