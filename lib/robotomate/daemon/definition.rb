module Robotomate::Daemon::Definition
  class DaemonTemplater
    def daemon(daemon); @daemon = daemon end
    def host(host); @options[:host] = host end
    def port(port); @options[:port] = port end
    def debug(debug); @options[:debug] = debug end
    def initialize(name)
      @options = { :name => name }
    end
    def generate
      @daemon.new(@options)
    end
  end

  def define_daemon(name, &definition)
    dt = DaemonTemplater.new(name)
    dt.instance_eval(&definition)
    dt.generate
  end
end