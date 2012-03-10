require 'resque/tasks'

namespace :resque do
  task :setup => [ :environment ] do
    puts "Loaded Rails environment."
  end

end

namespace :redis do
  REDIS_PID = "/usr/local/var/run/redis.pid" # TODO: allow configuration of infer from conf
  REDIS_CONFIG = File.join(Rails.root, "config", "redis_development.conf")
  REDIS_SERVER = "/usr/local/bin/redis-server" # TODO: allow configuration
  task :start do
    running = false
    if File.exists?(REDIS_PID)
      begin
        Process.kill(0, File.read(REDIS_PID).to_i)
        puts "Redis already running; skipping start"
        running = true
      rescue Errno::ESRCH
        # Process not running, good
      end
    end
    unless running
      exec(REDIS_SERVER, REDIS_CONFIG)
    end
  end
  task :stop do
    puts "Stopping Redis"
    Process.kill("TERM", File.read(REDIS_PID).to_i)
  end
end
