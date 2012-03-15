class Robotomate::Daemon::EZSrve < Robotomate::Daemon
  class BadResponse < ::Exception; end

  def send_x10(device, command)
    begin
      self.send("send_x10_#{command.to_s}", device)
    rescue NoMethodError => e
      x = e.exception("No command method #{command.to_s} for #{self.class.name})")
      x.set_backtrace(e.backtrace)
      raise x
    end
  end

  protected
  X10_RESPONSE_MSG = /<Response\s+Name="SendX10"\s+Status="([^"]*)".*<\/Response>/
  def send_x10_on(device)
    debug_log("Turning on device #{device}")
    msg = x10_message(device, "On")
    self.send_and_verify_x10(msg)
  end
  def send_x10_off(device)
    msg = x10_message(device, "Off")
    self.send_and_verify_x10(msg)
  end
  def send_x10_dim(device)
    msg = x10_message(device, "Dim")
    self.send_and_verify_x10(msg)
  end
  def send_x10_bright(device)
    msg = x10_message(device, "Bright")
    self.send_and_verify_x10(msg)
  end

  def x10_message(device, command)
    "<Command Name=\"SendX10\" House=\"#{device.house}\" Unit=\"#{device.unit}\" Cmd=\"#{command}\" />"
  end
  def x10_response_status
    res = self.wait_for(X10_RESPONSE_MSG)
    response = res[:success] ? res[:capture][1] : nil
    raise BadResponse.new("Bad response from device: #{res.pretty_inspect}") unless (response && response.match(/Success/))
    response
  end
  def send_and_verify_x10(msg)
    self.send_msg(msg)
    response = self.x10_response_status
    raise FailureResponse("Bad response from device") unless response
    response
  end
end
