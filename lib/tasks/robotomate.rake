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
  task :list_cmds, [ :daemon_name ] => [ :environment, "redis:start" ] do |_, args|
    daemon_name = args[:daemon_name] || ENV["daemon_name"]
    if daemon_name.blank?
      puts "Please specify daemon_name"
      return
    end
    jobs = []
    while true
      res = Resque.peek(daemon_name, 0, 100)
      break if res.empty?
      jobs += res
    end
    if jobs.empty?
      puts "No tasks for #{daemon_name}"
    else
      puts jobs.map { |job| job.inspect }.join("\n")
    end
  end
  task :list_daemons, [ :all ] => [ :environment, "redis:start" ] do |_, args|
    all = args[:all] || ENV["all"]
    known_daemons = Robotomate::Daemon.all_daemons.keys
    queued_daemons = Resque.queues
    puts "Daemons:"
    known_daemons.each { |name| puts "  #{name}" }
    puts "Defunct queues:"
    puts queued_daemons.inspect
  end
end