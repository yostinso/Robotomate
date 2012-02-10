require 'robotomate/devices/x10'
class Robotomate::Devices::X10::Lamp < Robotomate::Devices::X10
  MAX_BRIGHT=18
  MIN_BRIGHT=1
  def off
    @dim_level = MIN_BRIGHT-1
    super
  end
  def on
    @dim_level = MAX_BRIGHT if self.off?
    super
  end

  def dim
    @daemon.send_cmd(self, :dim)
    if self.off?
      @dim_level = MAX_BRIGHT
    elsif (@dim_level && @dim_level > MIN_BRIGHT)
      @dim_level -= 1 
    end
  end
  def bright
    @daemon.send_cmd(self, :bright)
    if self.off?
      @dim_level = MAX_BRIGHT
    elsif (@dim_level && @dim_level < MAX_BRIGHT)
      @dim_level += 1
    end
  end
  alias_method :brighten, :bright

  def dim_to(val)
    raise ArgumentError.new("Invalid dim level #{val}, must be between #{MIN_BRIGHT-1} and #{MAX_BRIGHT}") unless (val.to_i >= (MIN_BRIGHT-1) && val.to_i <= MAX_BRIGHT)
    reset_dim

    val = val.to_i
    full_off = (val < MIN_BRIGHT)
    val = MIN_BRIGHT if val < MIN_BRIGHT

    while @dim_level != val
      if @dim_level > val
        self.dim
      else
        self.bright
      end
    end

    self.off if full_off
  end
  protected
  def reset_dim
    if @dim_level.nil?
      reset_dim!
    end
  end
  def reset_dim!
    self.off if @state != :off
    self.on
  end
end
