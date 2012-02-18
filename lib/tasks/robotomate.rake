namespace :robotomate do
  namespace :listener do
    task :start => [ :environment, "redis:start" ] do
      require "script/listener.rb"
    end
  end
  task :enqueue_cmd do
    cmd = ENV["cmd"]

  end
end