#!/usr/bin/env ruby

# Load the Rails environment
APP_PATH = File.expand_path('../../config/application',  __FILE__)
CONF_PATH = File.expand_path('../../config/daemons.yml',  __FILE__)
require File.expand_path('../../config/boot',  __FILE__)
require File.expand_path('../../config/environment', __FILE__)

# Load our additions
require 'yaml'
require 'lib/robotomate'
require 'resque'
require 'spawn'

include Spawn

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

# This class inherits from Resque::Worker and runs any jobs that it's responsible for with @daemon as the first argument
class DaemonWorker < Resque::Worker
  def initialize(daemon, *queues)
    super(queues)
    @daemon = daemon
  end
  def reserve
    job = super
    if (job)
      job.payload['args'] = job.payload['args'] || []
      job.payload['args'].unshift(@daemon)
    end
    job
  end
end

# These workers will run against queues of Robotomate::Daemon::Command_COMMAND_ID classes, which
# are dynamically defined at runtime when the daemons are initialized in order to give
# them the correct queue name.
def start_worker(daemon)
  spawn_block do
    queue = "#{daemon.queue_identifier}"
    interval = 0.5

    worker = DaemonWorker.new(queue)
    worker.verbose = true
    worker.very_verbose = false

    worker.log "Starting worker #{worker} on queue #{queue} with #{interval} second intervals"
    worker.work(interval) # interval, will block
  end
end

spawned_procs = []
@drivers.values.each do |daemon|
  spawned_procs.push start_worker(daemon)
end

begin
  wait(spawned_procs)
rescue Interrupt => e
  # Kill the workers
  spawned_procs.each do |spawn_id|
    Process.kill("TERM", spawn_id.handle) # Kill workers and shutdown
  end
  wait_end = Time.now + 5.seconds
  any_alive = true
  while Time.now < wait_end do
    any_alive = spawned_procs.map { |spawn_id| Spawn.alive?(spawn_id.handle) }.find { |alive| alive }
    break if !any_alive
  end
  if !any_alive
    puts "Children terminated... exiting."
  else
    puts "Timed out waiting for children to terminate... exiting."
  end
end
