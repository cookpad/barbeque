class ChangeBarbequeRetryConfigsBaseDelayDefaultValue < ActiveRecord::Migration[5.2]
  def up
    change_column_default :barbeque_retry_configs, :base_delay, 15
  end

  def down
    change_column_default :barbeque_retry_configs, :base_delay, 0.3
  end
end
