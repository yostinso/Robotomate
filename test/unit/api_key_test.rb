# == Schema Information
#
# Table name: api_keys
#
#  id         :integer         not null, primary key
#  user_id    :integer
#  key        :string(255)
#  comment    :string(255)
#  created_at :datetime
#  updated_at :datetime
#

require 'test_helper'

class ApiKeyTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
