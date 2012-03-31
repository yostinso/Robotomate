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

class Device::X10 < Device
  before_save :check_valid_address
  JSNAME = "Device.X10"
  def house
    self.address.split(/:/)[0]
  end
  def unit
    self.address.split(/:/)[1]
  end
  def on
    raise NoDaemonException.new() unless @daemon
    @daemon.send_cmd(self, :on)
    self.state = :on
  end
  def off
    raise NoDaemonException.new() unless @daemon
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
    { :id => self.id, :name => self.name, :state => self.state }
  end

  private
  def check_valid_address
    # A-P, 1-16
    return !self.address.blank? && self.address.match(/^[A-P]:([1-9]|1[0-6])$/) ? true : false
  end
end
