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

class ApiKey < ActiveRecord::Base
end
