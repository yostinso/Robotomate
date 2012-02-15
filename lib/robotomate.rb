ROOT = File.dirname(File.expand_path('./', __FILE__))
require File.join(ROOT, 'robotomate', 'daemon')
[ "ez_srve", "lirc", "win_lirc" ].each do |daemon|
  require File.join(ROOT, 'robotomate', 'daemon', daemon)
end
