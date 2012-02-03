require 'socket'
require 'pp'
class Robotomate
  class Daemon
    @@daemons = {}

    def initialize(options)
      @@daemons["#{options['host']}:#{options['port']}"] = self
      @host = options['host']
      @port = options['port']
      @debug = options['debug']
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
      timeout_ms = timeout.to_f / 1000
      listeners = IO.select([ @socket ], nil, nil, timeout_ms)
      if listeners && listeners[0].include?(@socket)
        if @socket.eof?
          @socket.puts "effyou"
          raise new Exception("Disconnected by remote side")
        else
          res = gets_nonblock(@socket, timeout)
          debug_log "  Read: #{res}"
          return res
        end
      else
        debug_log "  No data."
        return nil
      end
    end
    def wait_for(regex, multiline = true, timeout = 1500)
      if !!(regex.options & Regexp::MULTILINE) != multiline
        new_opts = (regex.options & ~Regexp::MULTILINE)
        new_opts |= Regexp::MULTILINE if multiline
        regex = Regexp.new(regex.source, new_opts)
      end
      ms_timeout = timeout > 0 ? timeout/1000 : 0
      debug_log "Looking for #{regex.inspect} in the next #{ms_timeout} seconds"
      start = Time.now
      captured = { :success => false, :last => nil, :capture => nil, :all => [] }
      while (true) do
        captured[:last] = read_next
        if captured[:last]
          captured[:all].push captured[:last]
          captured[:capture] = regex.match(captured[:all].join("\n"))
          captured[:success] = !!captured[:capture]
        end
        break if captured[:capture]
        break if (start + ms_timeout < Time.now)
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
      @socket = TCPSocket.open(@host, @port)
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
    def gets_nonblock(socket, timeout=100)
      timeout_ms = timeout.to_f / 1000
      res = ""
      while true do
        listeners = IO.select([ socket ], nil, nil, timeout_ms)
        if listeners && listeners[0].include?(socket)
          break if socket.eof?
          char = socket.read_nonblock(1)
          res += char
          break if char == "\n"
        else
          break
        end
      end
      res
    end
  end
end

Dir.glob(File.join(File.dirname(__FILE__), "daemon", "*.rb")).each { |d| require d }
