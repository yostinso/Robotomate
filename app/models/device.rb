# == Schema Information
#
# Table name: devices
#
#  id         :integer         not null, primary key
#  address    :string(255)
#  state      :text
#  type       :string(255)
#  created_at :datetime
#  updated_at :datetime
#  name       :string(255)
#  extra      :text
#

class Device < ActiveRecord::Base
  class NoDaemonException < ::Exception; end

  @daemon = nil
  attr_accessor :daemon

  def initialize(options = nil)
    super
    self.daemon = options[:daemon] if options
  end

  # Set the state, converting from a {Symbol} to a {String} if necessary
  # @param [Symbol|String] state the new state
  def state=(state)
    write_attribute(:state, state.to_s)
  end

  # Set the state and save immediately, using {#state=}
  # @param [Symbol|String] state the new state
  # @raise [ActiveRecordError] if the save fails
  def set_state!(state)
    self.state = state
    self.save!
  end

  # Get the current device state as a {Symbol}
  # @return [Symbol] the current device state
  def state
    s = self.attributes[:state]
    s.nil? ? s : s.to_sym
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
