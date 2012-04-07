class Robotomate::Daemon::EZSrve < Robotomate::Daemon
  class BadResponse < ::Exception; end

  def send_x10(device, command)
    begin
      self.send("send_x10_#{command.to_s}", device)
    rescue NoMethodError => e
      x = e.exception("No command method send_x10_#{command.to_s} for #{self.class.name})")
      x.set_backtrace(e.backtrace)
      raise x
    end
  end

  def send_insteon(device, command)
    begin
      self.send("send_insteon_#{command.to_s}", device)
    rescue NoMethodError => e
      x = e.exception("No command method send_insteon_#{command.to_s} for #{self.class.name})")
      x.set_backtrace(e.backtrace)
      raise x
    end
  end

  protected
  # X10
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

  # Insteon
  INSTEON_RESPONSE_MSG = /<Response\s+Name="SendInsteon"\s+ID="([^"]*)"\s+Status="([^"]*)">(.*)<\/Response>/
  def send_insteon_on(device)
    debug_log("Turning on device #{device}")
    msg = insteon_message(device, "0x11", "0xFF")
    self.send_and_verify_insteon(msg, device.address)
  end
  def send_insteon_off(device)
    debug_log("Turning off device #{device}")
    msg = insteon_message(device, "0x13")
    self.send_and_verify_insteon(msg, device.address)
  end

  def insteon_message(device, cmd1, cmd2 = nil, data = nil)
    cmd_detail = "<CommandDetail Cmd1=\"#{cmd1}\""
    cmd2 = cmd2.blank? ? "0x00" : cmd2
    cmd_detail += " Cmd2=\"#{cmd2}\""
    cmd_detail += " Data=\"#{data}\"" unless data.blank?
    cmd_detail += " />"
    "<Command Name=\"SendInsteon\" ID=\"#{device.address}\">#{cmd_detail}</Command>"
  end
  def insteon_response_status(expected_addr)
    res = self.wait_for(INSTEON_RESPONSE_MSG)
    if res[:success]
      addr = res[:capture][1]
      response = res[:capture][2]
      content = res[:capture][3]
      raise BadResponse.new("Device did not return success: #{res.pretty_inspect}") unless addr == expected_addr
    else
      raise BadResponse.new("Cannot parse response from device: #{res.pretty_inspect}")
    end
    content
  end
  def send_and_verify_insteon(msg, address)
    self.send_msg(msg)
    response = self.insteon_response_status(address)
    raise FailureResponse("Bad response from device") unless response
    response
  end
end
