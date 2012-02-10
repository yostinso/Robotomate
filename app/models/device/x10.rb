class Device::X10 < Device
  attr_reader :house, :unit
  def initialize(house, unit, daemon)
    @house = house
    @unit = unit
    @daemon = daemon

    @state = nil
  end
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
end

Dir.glob(File.join(File.dirname(__FILE__), "*", "*.rb")).each { |d| require d }
