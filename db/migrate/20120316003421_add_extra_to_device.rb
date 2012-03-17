class AddExtraToDevice < ActiveRecord::Migration
  def change
    add_column :devices, :extra, :text
  end
end
