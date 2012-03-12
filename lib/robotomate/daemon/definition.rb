module Robotomate::Daemon::Definition
  class DaemonTemplater
    def daemon(daemon); @daemon = daemon end
    def host(host); @options[:host] = host end
    def port(port); @options[:port] = port end
    def debug(debug); @options[:debug] = debug end
    def initialize(name)
      @name = name
      @options = { :name => name }
    end
    def generate
      # Create a queuing class for this if it doesn't already exist
      unless Robotomate::Daemon::QueuedCommand.const_defined?(@name.to_sym)
        klass = Class.new(Robotomate::Daemon::QueuedCommand)
        klass.instance_variable_set(:@queue, @name)
        Robotomate::Daemon::QueuedCommand.const_set(@name.to_sym, klass)
      end

      # Generate an instance of the daemon
      @daemon.new(@options)
    end
  end

  def define_daemon(name, &definition)
    dt = DaemonTemplater.new(name)
    dt.instance_eval(&definition)
    dt.generate
  end
end