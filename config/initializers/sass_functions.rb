module Sass::Script::Functions
  def log_percent(percent)
    p = Sass::Script::Number.new(percent+1)
    unless (0..100).include?(percent.value)
      raise ArgumentError.new(
                "Percent #{percent} must be between 0% and 100%"
            )
    end
    Sass::Script::Number.new(((Math.log(percent).to_f / Math.log(101).to_f)*100).to_i)
  end
  declare :log_percent, :args => [:percent]
end