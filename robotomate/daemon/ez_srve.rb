class Robotomate::Daemon::EZSrve < Robotomate::Daemon
  def send_x10(device, command)
    begin
      self.send("send_x10_#{command.to_s}", device)
    rescue NoMethodError => e
      x = e.exception("No command method #{command.to_s} for #{self.class.name})")
      x.set_backtrace(e.backtrace)
      raise x
    end
  end

  private
  def x10_message(device, command)
    "<Command Name=\"SendX10\" House=\"#{device.house}\" Unit=\"#{device.unit}\" Cmd=\"#{command}\" />"
  end
  def send_x10_on(device)
    msg = x10_message(device, "On")
  end
end
