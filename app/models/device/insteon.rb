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

class Device::Insteon < Device
  include DeviceValidations
  before_method [ :on, :off ], :ensure_daemon_exists

  def on
    @daemon.send_cmd(self, :on)
    self.state = :on
  end
  def off
    @daemon.send_cmd(self, :off)
    self.state = :off
  end

  # TODO: Query the device
  def off?
    self.state == :off
  end
  def on?
    self.state == :on
  end

  def to_s
    "Insteon<#{address}>[#{state}]"
  end
  def to_h
    { :id => self.id, :name => self.name, :state => self.state, :type => self.js_type }
  end

  def self.matches_address(address)
    # FF.FF.FF
    (address || '').gsub(/\s/, '').match(/^([0-9A-F]{2})\.?([0-9A-F]{2})\.?([0-9A-F]{2})$/)
  end

  private
  def check_valid_address
    _, a, b, c = self.class.matches_address(self.address).to_a
    ok = !self.address.blank? && !a.blank? && !b.blank? && !c.blank?
    self.address = [a, b, c].join(".") if ok
    self.errors.add(:address, "is invalid") unless ok
    return ok
  end
end
