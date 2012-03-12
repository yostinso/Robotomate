namespace :robotomate do
  namespace :daemons do
    desc "Start Resque workers for each of the daemons defined in config/daemons.rb"
    task :start => [ :environment, "redis:start" ] do
      include Spawn
      if File.exists?("/dev/null") && !ENV["DEBUG"]
        Spawn.send(:class_variable_set, :@@logger, Logger.new("/dev/null"))
      end
      queues = Robotomate::Daemon.all_daemons.keys
      PID_ROOT = File.join(Rails.root, "tmp", "pids")

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

    desc "Stop Resque workers for each of the daemons defined in config/daemons.rb"
    task :stop => [ :environment ] do
      queues = Robotomate::Daemon.all_daemons.keys
      PID_ROOT = File.join(Rails.root, "tmp", "pids")
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

    desc "List the running status of the Resque workers defined in config/daemons.rb; daemon_name is optional"
    task :status, [ :daemon_name ] => [ :environment, "redis:start" ] do |_, args|
      include Spawn
      queues = Robotomate::Daemon.all_daemons.keys
      PID_ROOT = File.join(Rails.root, "tmp", "pids")
      daemon_name = args[:daemon_name] || ENV["daemon_name"]
      if daemon_name.blank?
        queues.each { |queue|
          pid_file = File.join(PID_ROOT, "resque_#{queue}.pid")
          if File.exists?(pid_file)
            if Spawn.alive?(File.read(pid_file).to_i)
              puts "#{queue}\trunning"
            else
              puts "#{queue}\tdied (pidfile still exists)"
            end
          else
            puts "#{queue}\tstopped"
          end
        }
      else
        pid_file = File.join(PID_ROOT, "resque_#{daemon_name}.pid")
        if File.exists?(pid_file)
          if Spawn.alive?(File.read(pid_file).to_i)
            puts "running"
          else
            puts "died"
          end
        else
          puts "stopped"
        end
      end
    end
  end

  desc "Enqueue a command for a particular device and daemon, e.g. robotomate:enqueue[on,Ez_Srve_1,3]"
  task :enqueue, [ :cmd, :daemon_name, :device_id ] => [ :environment,  "redis:start" ] do |_, args|
    cmd = args[:cmd] || ENV["cmd"]
    daemon_name = args[:daemon_name] || ENV["daemon_name"]
    device_id = args[:device_id] || ENV["device_id"]
    raise ArgumentError.new("cmd, daemon_name, and device_id all required") unless (cmd && daemon_name && device_id)
    raise ArgumentError.new("Invalid daemon") unless Robotomate::Daemon.all_daemons.has_key?(daemon_name)
    raise ArgumentError.new("Invalid device") unless Device.exists?(device_id.to_i)
    Robotomate::Daemon.all_daemons[daemon_name].send_cmd(Device.find(device_id.to_i), cmd)
  end
  namespace :list do
    desc "List queued commands; set daemon_name to filter for a specific daemon."
    task :commands, [ :daemon_name ] => [ :environment, "redis:start" ] do |_, args|
      daemon_name = args[:daemon_name] || ENV["daemon_name"]
      if daemon_name.blank?
        queues = Robotomate::Daemon.all_daemons.keys
      else
        queues = daemon_name.split(/,\s*/)
      end
      queues.each do |queue|
        puts queue
        jobs = []
        i = 0
        while true
          res = Resque.peek(queue, i, 100)
          break if res.empty?
          jobs += res
          i += 100
        end
        if jobs.empty?
          puts "  <no commands queued>"
        else
          jobs.each { |job| puts "  #{job["class"]}(#{job["args"].join(", ")})" }
        end
      end
    end
    desc "List the daemons configured in config/daemons.rb"
    task :daemons => [ :environment, "redis:start" ] do
      known_daemons = Robotomate::Daemon.all_daemons.keys
      queued_daemons = Resque.queues
      puts "Daemons:"
      known_daemons.each { |name| puts "  #{name}" }
      puts "Defunct queues:"
      (queued_daemons - known_daemons).each { |name| puts "  #{name}" }
    end
    desc "List devices from the database."
    task :devices => [ :environment ] do
      devices = Device.all.sort { |d1, d2| [d1.type, d1.address, d1.name].join(":") <=> [d2.type, d2.address, d2.name].join(":")}
      devices = devices.map { |d| [ d.id.to_s, d.type, d.address, d.name ]}
      devices.unshift([ "ID", "Type", "Address", "Name" ])
      colwidths = [ 0, 0, 0, 0 ]
      devices.each { |d|
        d.each_index { |i| colwidths[i] = [ d[i].length, colwidths[i] ].max }
      }
      puts "Devices:"
      devices.each { |d|
        puts "  " + [
          d[0].rjust(colwidths[0]+1) + "   ",
          d[1].ljust(colwidths[1]+3),
          d[2].ljust(colwidths[2]+3),
          d[3]
        ].join()
      }
    end
  end

  desc "Remove an entire command queue; use this to either purge a queue or to clean one that is no longer used."
  task :remove_queue, [ :daemon_name ] => [ :environment, "redis:start" ] do |_, args|
    daemon_name = args[:daemon_name] || ENV["daemon_name"]
    Resque.remove_queue(daemon_name)
  end
end