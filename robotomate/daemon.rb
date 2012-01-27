require 'socket'
class Robotomate
  class Daemon
    @@daemons = {}

    def initialize(options)
      @@daemons["#{options[:host]}:#{options[:port}"] = self
      @host = options[:host]
      @port = options[:port]
      @debug = options[:debug]
    end

    def send_msg(msg)
      debug_log "Sending: #{msg}"
      @socket.print msg
    end
    def send_cmd(device, command)
      begin
        self.send("send_#{short_name(device)}", device, command)
      rescue NoMethodError => e
        x = e.exception("No device method send_#{short_name(device)} for #{self.class.name})")
        x.set_backtrace(e.backtrace)
        raise x
      end
    end
    def read_next(timeout = 100)
      listeners = IO.select([ @socket ], nil, nil, 100)
      debug_log "Attempting to read: #{res}"
      if listeners.include?(@socket)
        if @socket.eof?
          raise new Exception("Disconnected by remote side")
        else
          res = @socket.gets()
          debug_log "  Read: #{res}"
          return res
        end
      else
        debug_log "  No data."
        return nil
      end
    end
    def wait_for(regex, timeout = 1500)
      ms_timeout = timeout > 0 ? timeout/1000 : 0
      start = Time.now
      captured = { :success => false, :last => nil, :capture => nil, :all => [] }
      while (true) do
        captured[:last] = read_next
        if captured[:last]
          captured[:capture] = regex.match(captured[:last])
          captured[:success] = !!captured[:capture]
          captured[:all].push captured[:last]
        end
        break if (start + ms_timeout > Time.now)
      end
      return captured
    end

    def connected?
      @socket && !@socket.eof?
    end
    def reconnect
      disconnect
      connect
    end
    def connect
      @socket = TCPSocket.open(options[:host], :options[:port])
    end
    def disconnect
      @socket.close
    end

    def self.cleanup
      @@daemons.each { |daemon| daemon.disconnect }
    end

    protected
    def short_name(device)
      device.class.name.sub(/^Robotomate::Daemon::/, '').downcase.gsub(/[^a-z0-9]+/, '_')
    end

    private
    def debug_log(msg)
      $stderr.puts msg if @debug
    end
  end
end

Dir.glob(File.join(File.dirname(__FILE__), "daemon", "*.rb")).each { |d| require d }
