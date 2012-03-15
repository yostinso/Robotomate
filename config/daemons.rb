include Robotomate::Daemon::Definition

if Rails.env == "test"
  # Don't define any daemons in the test environment
elsif Rails.env == "development"
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
elsif Rails.env == "production"
  define_daemon :Ez_Srve_121 do
    daemon Robotomate::Daemon::EZSrve
    host "192.168.2.121"
    port 8002
  end
  define_daemon :Lirc_104 do
    daemon Robotomate::Daemon::LIRC
    host "192.168.2.104"
    port 8765
  end
end
