class Device::X10 < Device
  before_save :check_valid_address
  JSNAME = "Device.X10"
  def house
    self.address.split(/:/)[0]
  end
  def unit
    self.address.split(/:/)[1]
  end
  def 
  def on
    @daemon.send_cmd(self, :on)
    @state = :on
  end
  def off
    @daemon.send_cmd(self, :off)
    @state = :off
  end
  def off?
    @state == :off
  end
  def on?
    @state == :on
  end

  private
  def check_valid_address
    # A-P, 1-16
    return !!(self.address.match(/^[A-P]:([1-9]|1[0-6])$/))
  end
end
