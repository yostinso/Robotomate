class DeviceGroup < ActiveRecord::Base
  has_and_belongs_to_many :devices
end
