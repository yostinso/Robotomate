require 'pp'
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
    msg = x10_message(device, "On")
    self.send_msg(msg)
    raise FailureResponse("Bad response from device") unless self.x10_response_status
    puts res.pretty_inspect
  end
  def send_x10_off(device)
    msg = x10_message(device, "Off")
    self.send_msg(msg)
    res = self.x10_response_status
    puts res.pretty_inspect
  end

  def x10_message(device, command)
    "<Command Name=\"SendX10\" House=\"#{device.house}\" Unit=\"#{device.unit}\" Cmd=\"#{command}\" />"
  end
  def x10_response_status
    res = self.wait_for(X10_RESPONSE_MSG)
    response = res[:capture][1] if res[:success]
    raise BadResponse.new("Bad response from device: #{res.pretty_inspect}") unless response.match(/Success/)
    response
  end
end
