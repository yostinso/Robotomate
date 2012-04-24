# == Schema Information
#
# Table name: devices
#
#  id          :integer         not null, primary key
#  address     :string(255)
#  state       :text
#  type        :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#  name        :string(255)
#  extra       :text
#  daemon_name :string(255)
#

class Device::X10 < Device
  include DeviceValidations
  before_method [ :on, :off ], :ensure_daemon_exists

  def house
    self.address.split(/:/)[0]
  end
  def unit
    self.address.split(/:/)[1]
  end
  def on
    @daemon.send_cmd(self, :on)
    self.state = :on
  end
  def off
    @daemon.send_cmd(self, :off)
    self.state = :off
  end
  def off?
    self.state == :off
  end
  def on?
    self.state == :on
  end

  def to_s
    "X10<#{address}>[#{state}]"
  end
  def to_h
    { :id => self.id, :name => self.name, :state => self.state, :type => self.js_type }
  end
  def self.matches_address(address)
    (address || '').gsub(/\s/, '').match(/^([A-P]):?([1-9]|1[0-6])$/)
  end

  private
  def check_valid_address
    # A-P, 1-16
    house, number = self.matches_address(self.address)
    ok = !self.address.blank? && !house.blank? && !number.blank?
    self.address = [ house, number ].join(":") if ok
    self.errors.add(:address, "is invalid") unless ok
    return ok
  end
end
