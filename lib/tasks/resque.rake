require 'resque/tasks'

namespace :resque do
  task :setup => [ :environment ] do
    puts "Loaded Rails environment."
  end

end

namespace :redis do
  def get_config
    config_template = File.read(File.join(Rails.root, "config", "redis_template.conf"))
    config_options = REDIS_CONFIG[Rails.env]

    config_options["dir"] = File.join(Rails.root, config_options["dir"]) unless config_options["dir"].start_with?("/")
    config_options.each { |k, v|
      config_template.gsub!(/\$\{#{k}\}/, v.to_s)
    }

    redis_db_dir = config_template.match(/dir (.*)$/)[1]
    redis_pid = config_template.match(/pidfile (.*)$/)[1]
    return config_options["redis_bin"], redis_db_dir, redis_pid, config_template
  end
  task :showconfig => [ :environment ] do
    redis_bin, redis_db_dir, redis_pid, redis_config = get_config()
    puts redis_config
    puts "# redis_bin: #{redis_bin}"
  end
  task :start => [ :environment ] do
    redis_bin, redis_db_dir, redis_pid, redis_config = get_config()

    if File.exists?(redis_pid)
      begin
        Process.kill(0, File.read(redis_pid).to_i)
        # redis already running
        next
      rescue Errno::ESRCH
        # Process not running, good
      end
    end

    if Rails.env == "test"
      if File.exists?(redis_db_dir)
        puts "Cleaning Redis test DB"
        FileUtils.rm_r(redis_db_dir)
      end
    end

    FileUtils.mkdir_p(File.dirname(redis_pid)) unless File.directory?(File.dirname(redis_pid))
    FileUtils.mkdir_p(redis_db_dir) unless File.directory?(redis_db_dir)

    running = false
    unless running
      puts "Starting Redis..."
      IO.popen(redis_bin + " -", "w+") do |pipe|
        pipe.puts redis_config
        pipe.close
      end
    end
  end
  task :stop => [ :environment ] do
    redis_bin, redis_db_dir, redis_pid, redis_config = get_config()
    puts "Stopping Redis"
    if File.exists?(redis_pid)
      Process.kill("TERM", File.read(redis_pid).to_i)
    else
      puts "  Couldn't find #{redis_pid}"
    end
  end
end
