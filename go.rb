#!/usr/bin/ruby

require 'yaml'
require 'robotomate/daemon'

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
ezs.send_msg('<Command Name="SendX10" House="A" Unit="2" Cmd="Off" />')

require 'pp'
puts ezs.wait_for(/<Response\s+Name="SendX10"\s+Status="([^"]*)".*<\/Response>/, 3000).pretty_inspect

ezs.disconnect
