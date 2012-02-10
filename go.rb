#!/usr/bin/ruby

require 'yaml'
require 'robotomate/daemon'
require 'robotomate/devices'

config = YAML.load(File.read("daemons.yml"))
config.each do |driver_name, options|
  begin
    driver = Robotomate::Daemon.const_get(driver_name)
  rescue NameError => e
    raise "Could not load driver #{driver_name}"
  end
end
@drivers = {}
config.each do |driver_name, options|
    driver = Robotomate::Daemon.const_get(driver_name)
    @drivers[driver_name] = driver.new(options)
end

# TESTING
ezs = @drivers["EZSrve"]
ezs.connect

lamp = Robotomate::Devices::X10::Lamp.new("A", 2, ezs)
lamp.dim_to(0)

ezs.disconnect
