class Robotomate
  class Daemon
    def initialize(options)
    end
  end
end

Dir.glob(File.join(File.dirname(__FILE__), "daemon", "*.rb")).each { |d| require d }
