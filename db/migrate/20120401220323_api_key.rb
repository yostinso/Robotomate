class ApiKey < ActiveRecord::Migration
  def change
    create_table :api_keys do |t|
      t.integer :user_id, :null => false, :unique => true
      t.string :api_key, :null => false
      t.string :comment

      t.timestamps
    end
    add_index(:api_keys, :user_id, { :unique => true })
  end
end
