# == Schema Information
#
# Table name: devices
#
#  id         :integer         not null, primary key
#  address    :string(255)
#  state      :text
#  type       :string(255)
#  created_at :datetime
#  updated_at :datetime
#  name       :string(255)
#  extra      :text
#

require 'test_helper'

class DeviceTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
