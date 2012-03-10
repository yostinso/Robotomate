namespace :robotomate do
  namespace :listener do
    task :start => [ :environment, "redis:start" ] do
      require "script/listener.rb"
    end
  end
  task :enqueue_cmd, :cmd, :daemon_name, :device_id do |_, args|
    cmd = args[:cmd] || ENV["cmd"]
    daemon_name = args[:daemon_name] || ENV["daemon_name"]
    device_id = args[:device_id] || ENV["device_id"]
    Resque.enqueue(Robotomate::Daemon::QueuedCommand, daemon_name, device_id, cmd)
  end
end