namespace :robotomate do
  namespace :listener do
    task :start => [ :environment, "redis:start" ] do
      require "script/listener.rb"
    end
  end
  task :enqueue_cmd, :cmd, :daemon do |task, args|
    cmd = args[:cmd] || ENV["cmd"]
    puts cmd
  end
end