class User < ActiveRecord::Base
  validates_uniqueness_of :email

  has_and_belongs_to_many :device_groups

  def devices
    device_groups.map { |dg| dg.devices }.flatten.uniq
  end
end
