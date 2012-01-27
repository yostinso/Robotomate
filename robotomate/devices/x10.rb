require 'robotmate/devices'
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
end

end
