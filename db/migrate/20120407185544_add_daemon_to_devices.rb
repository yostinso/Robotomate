class AddDaemonToDevices < ActiveRecord::Migration
  def change
    add_column :devices, :daemon, :string
  end
end
