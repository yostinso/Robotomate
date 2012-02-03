class Robotomate::Devices
  class NoDaemonException < ::Exception; end
end

Dir.glob(File.join(File.dirname(__FILE__), "devices", "*.rb")).each { |d| require d }
