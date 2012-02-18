require 'socket'
module Robotomate
  class Daemon
    class InvalidDevice < ::Exception; end
    class NotConnected < ::Exception; end
    @@daemons = {}

    def initialize(options)
      options = HashWithIndifferentAccess.new(options)
      @host = options[:host]
      @port = options[:port]
      @debug = options[:debug]
      @connected = false
      @@daemons[self.class.name + "::" + self.identifier] = self

      # Create a dynamic subclass for doing Resque work
      # This requires some explanation:
      #   Basically, we need a difference class instance variable @queue for each
      #   queue that we want to insert jobs into, and since we want each instance
      #   of each daemon (with its own port etc) to have its own queue, we create
      #   the command class on the fly. (It will be created inside Rails/web as
      #   soon as any daemons are initialized to enqueue commands, and it will
      #   be created inside the listener.rb script as soon as daemons are initialized
      #   to send/recv commands.)
      if self.class != Robotomate::Daemon
        klass_name = "Command_" + self.identifier
        if (!self.class.const_defined?(klass_name))
          queue_name = self.queue_identifier
          @command_class = self.class.const_set(klass_name, Class.new {
            @queue = queue_name
          })
          @command_class.send(:define_method, :perform, self.perform_method)
        end
      end
    end

    def perform_method
      Proc.new { |daemon| $stderr.puts "WHAT" }
    end
    def identifier
      [@host, @port].join("_").gsub(/[^a-zA-Z0-9_]/, '_')
    end
    def queue_identifier
      self.class.name.downcase.gsub(/[^a-z0-9]/, '_') + "_" + self.identifier + "_commands"
    end
    def send_msg(msg)
      debug_log "Sending: #{msg}"
      @socket.print msg
    end
    def send_cmd(device, command)
      raise InvalidDevice.new("Invalid device: #{device.class.name}") unless device.is_a?(Robotomate::Devices)
      raise NotConnected.new("Daemon not connected") unless self.connected?
      klass = device.class
      method_name = nil
      while klass.ancestors.include?(Robotomate::Devices) do
        method_name = "send_#{short_name(klass)}"
        if self.respond_to?(method_name)
          break
        else
          method_name = nil
          klass = klass.superclass
        end
      end

      if method_name
        self.send(method_name, device, command)
      else
        raise NoMethodError.new("No device method send_#{short_name(device)} for #{self.class.name})", "send_#{short_name(device)}")
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
        #debug_log "  No data."
        return nil
      end
    end
    def wait_for(regex, multiline = true, timeout = 5000)
      if ((regex.options & Regexp::MULTILINE)>0) != multiline
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
      @socket && @connected
    end
    def reconnect
      disconnect
      connect
    end
    def connect
      @socket = TCPSocket.open(@host, @port)
      @connected = true
    end
    def disconnect
      @connected = false
      @socket.close
    end

    def self.cleanup
      @@daemons.each { |daemon| daemon.disconnect }
    end

    protected
    def short_name(device_klass)
      device_klass.name.sub(/^Robotomate::Devices::/, '').downcase.gsub(/[^a-z0-9]+/, '_')
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
