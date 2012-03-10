class Device < ActiveRecord::Base
  class NoDaemonException < ::Exception; end

  @daemon = nil
  attr_accessor :daemon

  def initialize(options = nil)
    super
    self.daemon = options[:daemon] if options
  end

  # A helper method for setting the daemon the device will use that will return the device (for jQuery-style chaining)
  #
  # @param daemon the daemon to bind to
  # @return this device
  def set_daemon(daemon)
    @daemon = daemon
    self
  end
end
