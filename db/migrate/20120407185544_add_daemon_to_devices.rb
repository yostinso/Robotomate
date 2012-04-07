class AddDaemonToDevices < ActiveRecord::Migration
  def change
    add_column :devices, :daemon_name, :string
  end
end
