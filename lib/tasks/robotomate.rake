namespace :robotomate do
  namespace :daemons do
    task :start => [ :environment, "redis:start" ] do
      include Spawn
      if File.exists?("/dev/null") && !ENV["DEBUG"]
        Spawn.send(:class_variable_set, :@@logger, Logger.new("/dev/null"))
      end
      queues = Robotomate::Daemon.all_daemons.keys
      PID_ROOT = File.join(Rails.root, "tmp")

      # Backup env vars so we can restore them later
      ENV_VARS = [ "QUEUE", "QUEUES", "PIDFILE", "BACKGROUND" ]
      old_env_vars = ENV_VARS.inject(Hash.new) { |h, v| h[v] = ENV[v]; h }
      ENV.delete("QUEUES")
      ENV.delete("BACKGROUND")

      # Start the workers
      puts "Start workers for #{queues.join(", ")}"
      queues.each do |queue|
        pid_file = File.join(PID_ROOT, "resque_#{queue}.pid")
        ENV["QUEUE"] = queue.to_s
        ENV["PIDFILE"] = pid_file
        puts "  Starting worker on queue #{queue}"
        Spawn.spawn_block do
          Rake::Task["resque:work"].execute()
        end
      end

      # Restore env vars
      ENV_VARS.each { |v|
        if old_env_vars[v].nil?
          ENV.delete(v)
        else
          ENV[v] = old_env_vars[v]
        end
      }
    end
    task :stop => [ :environment ] do
      queues = Robotomate::Daemon.all_daemons.keys
      PID_ROOT = File.join(Rails.root, "tmp")
      pids = {}
      puts "Stopping #{queues.join(", ")}"
      queues.each do |queue|
        pid_file = File.join(PID_ROOT, "resque_#{queue}.pid")
        next unless File.exists?(pid_file)
        pids[queue] = File.read(pid_file).to_i
        if Spawn.alive?(pids[queue])
          puts "  Killing #{queue} (#{pids[queue]})"
          Process.kill("TERM", pids[queue])
        end
      end

      # Wait for workers to exit
      any_alive = pids
      wait_end = Time.now + 5.seconds
      while Time.now < wait_end do
        pids.each { |queue, pid| any_alive.delete(queue) unless Spawn.alive?(pid) }
        break if any_alive.empty?
      end

      # Clean up files
      queues.each do |queue|
        pid_file = File.join(PID_ROOT, "resque_#{queue}.pid")
        next unless File.exists?(pid_file)
        File.delete(pid_file) unless any_alive.has_key?(queue)
      end

      if any_alive.empty?
        puts "  All workers stopped."
      else
        puts "  Failed to stop: " + any_alive.map { |queue, pid| "#{queue} (#{pid})" }.join(", ")
      end
    end
  end
  task :enqueue_cmd, :cmd, :daemon_name, :device_id do |_, args|
    cmd = args[:cmd] || ENV["cmd"]
    daemon_name = args[:daemon_name] || ENV["daemon_name"]
    device_id = args[:device_id] || ENV["device_id"]
    Resque.enqueue(Robotomate::Daemon::QueuedCommand, daemon_name, device_id, cmd)
  end
end