class CreateApps < ActiveRecord::Migration[5.0]
  def change
    create_table :apps, options: 'ENGINE=InnoDB ROW_FORMAT=dynamic DEFAULT CHARSET=utf8mb4' do |t|
      t.string :name, null: false
      t.string :docker_image, null: false
      t.text :description

      t.timestamps
    end
    add_index :apps, [:name], unique: true
  end
end
