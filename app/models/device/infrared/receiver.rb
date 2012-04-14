class Device::Infrared::Receiver < Device::Infrared
  def power
    raise NoDaemonException.new() unless @daemon
    @daemon.send_cmd(self, :power)
    if self.state == :on
      self.state = :off
    else
      self.state = :on
    end
  end

  def on
    if self.state != :on
      self.power
    end
  end

  def off
    if self.state == :on
      self.power
    end
  end


  def off?
    self.state == :off
  end
  def on?
    self.state == :on
  end

  def to_s
    "InfraredReceiver<#{address}>[#{state}]"
  end
  def to_h
    { :id => self.id, :name => self.name, :state => self.state, :type => self.js_type }
  end
end