class CreateDevices < ActiveRecord::Migration
  def change
    create_table :devices do |t|
      t.string :address
      t.text :state
      t.string :type

      t.timestamps
    end
  end
end
