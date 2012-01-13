#!/usr/bin/ruby

require 'yaml'
require 'robotomate/daemon'

config = YAML.load(File.read("daemons.yml"))
config.each do |driver, options|
  begin
    driver = Robotomate::Daemon.const_get(driver)
  rescue NameError => e
    raise "Could not load driver #{driver}"
  end
end
config.each do |driver, options|
    driver = Robotomate::Daemon.const_get(driver)
    driver.new(options)
end
