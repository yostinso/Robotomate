require 'bundler/capistrano'
load 'config/deploy/deploy_settings'
default_run_options[:pty] = true # to give a tty to sudo
set :use_sudo, false             # But don't use it if you can help it
set :ssh_options, {:forward_agent => true}

set :scm, :git # Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`
set :application, "robotomate"
set :repository,  "git@github.com:yostinso/Robotomate.git"

# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end

# Configs
namespace :db do
  task :setup, :except => { :no_release => true } do
    deploy = "config/deploy/database.yml"
    template = "config/deploy/database.yml.template"

    db_yml = deploy
    exist = (run_locally("sh -c 'if [ -e \"#{db_yml}\" ]; then echo true; else echo false; fi'") =~ /^true$/) ? true : false
    if !exist
      db_yml = template
      exist = (run_locally("sh -c 'if [ -e \"#{db_yml}\" ]; then echo true; else echo false; fi'") =~ /^true$/) ? true : false
    end
    raise "Database config not found in #{deploy} or #{template}" unless exist

    conf = run_locally("cat \"#{db_yml}\"")
    conf = ERB.new(conf).result(binding) if db_yml == template
    yml = YAML.load(conf)
    if yml['production'] && yml['production'] && yml['production']['adapter'] == "sqlite3"
      run "mkdir -p \"#{shared_path}/config\""
      run "mkdir -p \"#{shared_path}/db\""
      put conf, "#{shared_path}/config/database.yml"
    end
  end
  task :symlink, :roles => :db do
    conf_path = File.join(shared_path, "config", "database.yml")
    conf = capture("sh -c 'if [ -e \"#{conf_path}\" ]; then cat \"#{conf_path}\"; fi'")
    if conf.strip.length > 0
      yml = YAML.load(conf)
      if yml['production'] && yml['production'] && yml['production']['adapter'] == "sqlite3"
        run "ln -nfs \"#{conf_path}\" \"#{File.join(release_path, "config", "database.yml")}\""
      end
    end
  end
end
after "deploy:setup", "db:setup"
after "deploy:finalize_update", "db:symlink"
