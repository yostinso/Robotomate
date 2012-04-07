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
#  daemon     :string(255)
#

# @attr [Robotomate::Daemon] daemon the daemon through which communication with this device will occur
# @attr [Boolean] immediate_write (true) )whether or not to immediately update the database when the state changes
class Device < ActiveRecord::Base
  class NoDaemonException < ::Exception; end

  validates_exclusion_of :type, :in => %w(Device), :message => "Cannot create an abstract Device"
  validates_presence_of :type, :message => "Cannot create an abstract Device with no type"

  attr_accessor :daemon, :immediate_write
  serialize :extra, Hash
  before_save :ensure_extra_is_hash
  after_initialize :ensure_extra_is_hash, :set_instance_vars

  # Set the state, converting from a {Symbol} to a {String} if necessary
  # @param [Symbol|String] state the new state
  def state=(state)
    write_attribute(:state, state.to_s)
    self.save! if @immediate_write
  end

  # Get the current device state as a {Symbol}
  # @return [Symbol] the current device state
  def state
    s = read_attribute(:state)
    s.nil? ? s : s.to_sym
  end

  # Return the web-ready JSON data for this device
  # @return [String] JSON data
  def to_json
    self.to_h.to_json
  end

  # A helper method for setting the daemon the device will use that will return the device (for jQuery-style chaining)
  #
  # @param daemon the daemon to bind to
  # @return this device
  def set_daemon(daemon)
    @daemon = daemon
    self
  end

  private
  def ensure_extra_is_hash
    self.extra = Hash.new if self.extra.nil?
  end
  def set_instance_vars
    @daemon = nil
    @immediate_write = true
  end
end
