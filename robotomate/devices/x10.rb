class Robotomate::Devices::X10 < Robotomate::Devices
  attr_reader :house, :unit
  def initialize(house, unit, daemon = nil)
    @house = house
    @unit = unit
    @daemon = daemon
  end
  def on
    raise Robotomate::Devices::NoDaemonException unless (@daemon && @daemon.connected?)
    @daemon.send_cmd(self, :on)
  end
  def off
    raise Robotomate::Devices::NoDaemonException unless (@daemon && @daemon.connected?)
    @daemon.send_cmd(self, :off)
  end
end

Dir.glob(File.join(File.dirname(__FILE__), "*", "*.rb")).each { |d| require d }
