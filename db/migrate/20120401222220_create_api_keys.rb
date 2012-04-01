class CreateApiKeys < ActiveRecord::Migration
  def change
    create_table :api_keys do |t|
      t.integer :user_id
      t.string :key
      t.string :comment

      t.timestamps
    end
  end
end
