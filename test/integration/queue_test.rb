require 'test_helper'

class Robotomate::Daemon::Test < Robotomate::Daemon
  class BadResponse < ::Exception; end

  def connect
    rd, wr = IO.pipe
    @socket = wr
    @collect = rd
    @connected = true
  end
  def send_test_device(device, command)
    self.send("send_test_device_#{command.to_s}", device)
  end
  def send_test_device_test(device)
    self.send_msg("OK: #{device.id}")
  end
end
class Device::TestDevice < Device
  def test_cmd
    return @daemon.send_cmd(self, :test)
  end
end

class QueueTest < ActionDispatch::IntegrationTest
  fixtures :all

  include Robotomate::Daemon::Definition

  define_daemon :Test_Daemon do
    daemon Robotomate::Daemon::Test
    host "192.168.2.121"
    port 8002
    debug true
  end

  test "enqueue and run a command" do
    # TODO: Make a functional test from everything up to "run worker"
    raise "Redis not configured in the test environment" unless Resque.redis
    begin
      Resque.queues
    rescue Exception => e
      raise "Cannot connect to Redis in the test environment: #{e.message}"
    end

    # Clean queue
    Resque.remove_queue(:Test_Daemon)

    # enqueue command
    daemon = Robotomate::Daemon.all_daemons[:Test_Daemon]
    assert daemon, "Could not create test daemon"

    device = devices(:test_device)
    assert device, "Could not create test device"

    daemon.send_cmd(device, :test_cmd)

    cmds = Resque.peek(:Test_Daemon, 0, 10)
    assert_equal(1, cmds.length, "didn't queue a single command'")

    cmd = cmds.first
    assert_equal Robotomate::Daemon::QueuedCommand::Test_Daemon.name, cmd["class"], "command class is not QueuedCommand::Test_Daemon"
    assert_equal 3, cmd["args"].length, "command does not have 3 arguments: daemon, device, command"
    assert_equal "Test_Daemon", cmd["args"][0], "command queue is not 'Test_Daemon'"
    assert_equal device.id, cmd["args"][1], "command is not queued for device #{device.id}"
    assert_equal "test_cmd", cmd["args"][2], "command is not for the command 'test_cmd'"

    # fake job
    daemon.connect
    job = Resque::Job.reserve(:Test_Daemon)
    klass = Resque::Job.constantize(job.payload['class'])
    assert_equal klass, Robotomate::Daemon::QueuedCommand::Test_Daemon, "job class is not correct"

    klass.perform(*job.payload['args'])

    collect = daemon.instance_variable_get(:@collect)
    assert collect, "couldn't get output of test socket"
    begin
      res = collect.read_nonblock(1024)
    rescue
      res = nil
    end
    assert_equal "OK: #{device.id}", res, "didn't send expected message"
  end
end
