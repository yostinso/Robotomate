#!/usr/bin/env ruby

# Load the Rails environment
APP_PATH = File.expand_path('../../config/application',  __FILE__)
CONF_PATH = File.expand_path('../../config/daemons.yml',  __FILE__)
require File.expand_path('../../config/boot',  __FILE__)

require 'yaml'
require 'lib/robotomate'

config = YAML.load_file(CONF_PATH) #.map { |k, v| ["Robotomate::Daemon::" + k, v] }
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
