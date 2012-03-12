include Robotomate::Daemon::Definition

define_daemon :Ez_Srve_121 do
  daemon Robotomate::Daemon::EZSrve
  host "192.168.2.121"
  port 8002
  debug true
end
define_daemon :Lirc_104 do
  daemon Robotomate::Daemon::LIRC
  host "192.168.2.104"
  port 8765
  debug true
end
