class Robotomate::Daemon::Test < Robotomate::Daemon
  class BadResponse < ::Exception; end

  def connect
    @socket = $stderr
  end
  def send_x10_test

  end
  def method_missing(name, *args)
    if name =~ /^send/
      self.send_msg("TEST METHOD: #{name} with args (#{args.join(", ")})")
    else
      super
    end
  end
end
