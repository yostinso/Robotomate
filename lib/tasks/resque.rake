require 'resque/tasks'

namespace :resque do
  task :setup => [ :environment ] do
    puts "Loaded Rails environment."
  end
end

