class Robotomate::Daemon::LIRC < Robotomate::Daemon
  class BadResponse < ::Exception; end

  def send_infrared(device, command)
    begin
      self.send("send_infrared_#{command.to_s}", device)
    rescue NoMethodError => e
      x = e.exception("No command method send_infrared_#{command.to_s} for #{self.class.name})")
      x.set_backtrace(e.backtrace)
      raise x
    end
  end

  def send_infrared_power(device)
    msg = self.infrared_message_once(device, "power")
    self.send_and_verify_infrared(msg)
  end

  def send_msg(msg)
    super(msg + "\n")
  end

  protected
  INFRARED_RESPONSE_CODE = /BEGIN\n([^\n]*)\n([^\n]*)\nEND/
  def infrared_message_once(device, cmd)
    "SEND_ONCE #{device.address} #{cmd}"
  end
  def send_and_verify_infrared(msg)
    self.send_msg(msg)
    res = self.wait_for(INFRARED_RESPONSE_CODE)
    if res[:success]
      raise BadResponse.new("Response did not include the command we sent: #{res.pretty_inspect}") unless (res[:capture][1] == msg)
      raise BadResponse.new("Response indicated failure: #{res.pretty_inspect}") unless (res[:capture][2] == "SUCCESS")
      res[:capture][1]
    else
      raise BadResponse.new("Unparseable response: #{res.pretty_inspect}")
      nil
    end
  end
end
