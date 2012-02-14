rails_root = Rails.root || ENV['RAILS_ROOT'] || File.join(File.dirname(__FILE__), "..", "..")
rails_env = Rails.env || ENV['RAILS_ENV'] || 'development'

resque_config = YAML.load_file(File.join(rails_root, "config", "resque.yml"))
Resque.redis = resque_config[rails_env]
