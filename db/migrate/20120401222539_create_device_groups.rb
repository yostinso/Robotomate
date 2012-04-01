class CreateDeviceGroups < ActiveRecord::Migration
  def change
    create_table :device_groups do |t|
      t.string :name

      t.timestamps
    end

    # Link to Devices
    create_table :device_groups_devices, :id => false do |t|
      t.integer :device_group_id
      t.integer :device_id
    end
    add_index(:device_groups_devices, :device_group_id)
    add_index(:device_groups_devices, :device_id)

    # Link to Users
    create_table :device_groups_users, :id => false do |t|
      t.integer :user_id
      t.integer :device_group_id
    end
    add_index(:device_groups_users, :user_id)
    add_index(:device_groups_users, :device_group_id)
  end
end
