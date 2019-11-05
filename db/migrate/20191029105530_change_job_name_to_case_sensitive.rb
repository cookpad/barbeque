class ChangeJobNameToCaseSensitive < ActiveRecord::Migration[5.2]
  def up
    change_column :barbeque_job_definitions, :job, :string, collation: 'utf8mb4_bin'
  end

  def down
    change_column :barbeque_job_definitions, :job, :string, collation: nil
  end
end
