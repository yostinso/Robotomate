if defined?(Sass)
  module Sass::Script::Functions
    def log_percent(percent)
      p = (percent.value+1).to_f
      unless (0..100).include?(percent.value)
        raise ArgumentError.new(
                  "Percent #{percent} must be between 0% and 100%"
              )
      end
      Rails.logger.debug "FROM #{percent.value}: #{(((Math.log(p) / Math.log(101.to_f))*100).to_i)}"
      Sass::Script::Number.new(((Math.log(p) / Math.log(101.to_f))*100).to_i)
    end
    declare :log_percent, :args => [:percent]
  end
end
