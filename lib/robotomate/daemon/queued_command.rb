module Robotomate
  class Daemon
    class QueuedCommand
      def self.perform(daemon_name, device_id, command, *args)
        daemon = Robotomate::Daemon.all_daemons[daemon_name]
        Device.find(device_id).set_daemon(daemon).send(command, *args)
      end
    end
  end
end
