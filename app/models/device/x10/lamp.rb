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

class Device::X10::Lamp < Device::X10
  MAX_BRIGHT=18
  MIN_BRIGHT=1
  def off
    self.dim_level = MIN_BRIGHT-1
    super
  end
  def on
    self.dim_level = MAX_BRIGHT if self.off?
    super
  end

  def dim
    raise NoDaemonException.new() unless @daemon
    @daemon.send_cmd(self, :dim)
    if self.off?
      self.dim_level = MAX_BRIGHT
    elsif (self.dim_level && self.dim_level > MIN_BRIGHT)
      self.dim_level = self.dim_level - 1
    end
  end
  def bright
    raise NoDaemonException.new() unless @daemon
    @daemon.send_cmd(self, :bright)
    if self.off?
      self.dim_level = MAX_BRIGHT
    elsif (self.dim_level && self.dim_level < MAX_BRIGHT)
      self.dim_level = self.dim_level + 1
    end
  end
  alias_method :brighten, :bright

  def dim_to(val)
    raise ArgumentError.new("Invalid dim level #{val}, must be between #{MIN_BRIGHT-1} and #{MAX_BRIGHT}") unless (val.to_i >= (MIN_BRIGHT-1) && val.to_i <= MAX_BRIGHT)
    reset_dim

    val = val.to_i
    full_off = (val < MIN_BRIGHT)
    val = MIN_BRIGHT if val < MIN_BRIGHT
    val = MAX_BRIGHT if val > MAX_BRIGHT

    while self.dim_level != val
      if self.dim_level > val
        self.dim
      else
        self.bright
      end
    end

    self.off if full_off
  end

  def to_h
    super.merge({
      :dim_level => dim_level
    })
  end


  def dim_level
    extra[:dim_level]
  end
  protected
  def reset_dim
    if self.dim_level.nil?
      reset_dim!
    end
  end
  def reset_dim!
    self.off if @state != :off
    self.on
  end
  def dim_level=(level)
    extra[:dim_level] = level
    self.state = :on if level > 0
    self.state = :off if level <= 0
    self.save! if @immediate_write
  end
end
