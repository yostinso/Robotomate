class Device::Insteon::Lamp < Device::Insteon
  before_method [ :dim, :bright, :dim_to ], :ensure_daemon_exists
  MAX_BRIGHT=32
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
    @daemon.send_cmd(self, :dim)
    if self.off?
      self.dim_level = MAX_BRIGHT
    elsif (self.dim_level && self.dim_level > MIN_BRIGHT)
      self.dim_level = self.dim_level - 1
    end
  end
  def bright
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
    @daemon.send_cmd(self, :dim_to, val.to_i)
    self.dim_level = val
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
  def dim_level=(level)
    extra[:dim_level] = level
    self.state = :on if level > 0
    self.state = :off if level <= 0
    self.save! if @immediate_write
  end
end