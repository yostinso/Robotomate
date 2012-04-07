# == Schema Information
#
# Table name: users
#
#  id         :integer         not null, primary key
#  email      :string(255)
#  password   :string(255)
#  nickname   :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class User < ActiveRecord::Base
  validates_uniqueness_of :email

  has_and_belongs_to_many :device_groups

  def devices
    device_groups.map { |dg| dg.devices }.flatten.uniq
  end
end
