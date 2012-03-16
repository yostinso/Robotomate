rails_root = Rails.root || ENV['RAILS_ROOT'] || File.join(File.dirname(__FILE__), "..", "..")
rails_env = Rails.env || ENV['RAILS_ENV'] || 'development'

resque_config = YAML.load_file(File.join(rails_root, "config", "resque.yml"))
Resque.redis = resque_config[rails_env]

REDIS_CONFIG = YAML.load_file(File.join(rails_root, "config", "redis.yml"))

def Resque.logger
  @@resque_logger ||= Logger.new(File.join(Rails.root, "log", "#{Rails.env}-resque.log"))
  @@resque_logger
end
Resque::Worker.send(:define_method, :log) { |message|
  Rails.logger.info("resque: #{message}")
}

# This is needed to support mounting the Resque admin interface
if Rails.env != "test"
  require 'resque/server'
end
