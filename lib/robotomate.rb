ROOT = File.dirname(File.expand_path('./', __FILE__))
#noinspection RubyResolve
require File.join(ROOT, 'robotomate', 'daemon')
#noinspection RubyResolve
require File.join(ROOT, 'robotomate', 'daemon', "queued_command")
[ "ez_srve", "lirc", "win_lirc" ].each do |daemon|
  #noinspection RubyResolve
  require File.join(ROOT, 'robotomate', 'daemon', daemon)
end
