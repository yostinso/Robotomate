require 'socket'
module Robotomate
  class Daemon
    class InvalidDevice < ::Exception; end
    class NotConnected < ::Exception; end
    @@daemons = {}
    def self.all_daemons
      @@daemons
    end

    attr_reader :name
    # @param [Hash] options the options for initializing this daemon
    # @option options [String] :host the host IP or domain name this daemon will connect to
    # @option options [Integer] :port the port this daemon will connect to
    # @option options [Boolean] :debug whether this daemon should run in debugging mode
    # @option options [Name] :name a unique name for this daemon
    def initialize(options)
      options = HashWithIndifferentAccess.new(options)
      @host = options[:host]
      @port = options[:port]
      @debug = options[:debug]
      @name = options[:name]
      @connected = false

      raise ArgumentError.new("Daemon name '#{@name}' already used by #{Robotomate::Daemon.all_daemons[@name].to_s}") if Robotomate::Daemon.all_daemons[@name]
      Robotomate::Daemon.all_daemons[@name] = self
    end

    # Send a command to a particular device
    # If we're currently online (connected) then go ahead and send immediately
    # Otherwise, enqueue with Resque and let another instance of this daemon do it
    #
    # @param [Device] device the device to send the command to
    # @param [Symbol] command the command to send, e.g. :on
    # @param [Array] args* any further arguments to the device
    def send_cmd(device, command, *args)
      if connected?
        self.send_cmd_to_device(device, command, *args)
      else
        Resque.enqueue(QueuedCommand, @name, device.id, command, *args)
      end
    end

    # The connected state of this daemon
    #
    # @return [Boolean] whether or not this daemon thinks it's connected
    def connected?
      @socket && @connected
    end

    # Attempt to (re)connect this daemon to its endpoint, disconnecting first if possible.
    def reconnect
      begin
        disconnect
      rescue
        # ignored
      end
      connect
    end

    # Attempt to connect to this daemon's {IO::Socket} on its host and port
    # @see #initialize
    def connect
      @socket = TCPSocket.open(@host, @port)
      @connected = true
    end

    # Attempt to disconnect an already connected socket. Does nothing unless {#connected?} is true
    def disconnect
      #noinspection RubyControlFlowConversionInspection
      if !connected?
        @connected = false
        @socket.close
      end
    end

    def to_s
      self.class.name + "[#{@host}:#{@port}]<#{connected? ? '' : 'dis'}connected>"
    end

    protected
    # Provide the underscored/lowercased name of a device, used when calling a daemon's send* methods. The daemon
    # should have functions defined in the style send_<short_name>_<command>, e.g. send_x10_on.
    #
    # @param [Class] device_klass a subclass of Robotomate::Devices
    # @return [String] the short name of a device underscored/downcased, e.g. ez_srve
    # @see #send_cmd_to_device
    def short_name(device_klass)
      device_klass.name.sub(/^Robotomate::Devices::/, '').downcase.gsub(/[^a-z0-9]+/, '_')
    end

    # Just a wrapper for @socket.print that will optionally log the data being sent
    #
    # @param msg the string to send to the connected socket
    def send_msg(msg)
      debug_log "Sending: #{msg}"
      @socket.print msg
    end

    # Wait for the incoming data from the device to match a regex, and return the regex match by default. Forces any
    # incoming {RegExp} to be multiline by default. This method will eventually timeout and return regardless of whether
    # a match occurs.
    #
    # @param [RegExp] regex the regular expression to match agains the incoming data
    # @param [Boolean] multiline (true) whether the regular expression should match across newlines
    # @param [Integer] timeout (5000) the number of milliseconds to wait for the match to occur
    # @return [Hash] returns a hash with for keys: :success is true if the capture matched before the timeout, :last is
    #                the last line received, :capture is the {MatchData} object, :all is an array of all lines seen
    #                while waiting for regex to match.
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
          captured[:success] = captured[:capture] ? true : false
        end
        break if captured[:capture]
        break if (start + ms_timeout < Time.now)
      end
      return captured
    end

    # Read incoming data from the socket, up to one full line at a time. (see {#gets_nonblock}). Blocks until the
    # timeout is reached, and then returns any data received.
    #
    # @param [Integer] timeout (100) the number of milliseconds to wait for data
    # @return [String] the data captured, or nil if no data was returned
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

    # Send a command to a device supported by this daemon. Tries to find a method of the form
    # send_<device_short_name>_<command> that is accepted by this daemon for the device or any of its ancestors.
    # For example, if the daemon has a method send_x10_on, and the device is a {Device::X10::Lamp}, it
    # will first try send_x10_lamp_on before trying send_x10_on.
    #
    # @param [Device] device the device that you are trying to send a command to
    # @param [Symbol] command the command to send (can also be a {String})
    # @param args any additional arguments to the command
    # @raise [NoMethodError] thrown if no matching method could be found for the device or its ancestors
    # @see Robotomate::Daemon::EZSrve
    def send_cmd_to_device(device, command, *args)
      raise InvalidDevice.new("Invalid device: #{device.class.name}") unless device.is_a?(Device)
      raise NotConnected.new("Daemon not connected") unless self.connected?
      klass = device.class
      method_name = nil
      while klass.ancestors.include?(Device) do
        method_name = "send_#{short_name(klass)}"
        if self.respond_to?(method_name)
          break
        else
          method_name = nil
          klass = klass.superclass
        end
      end

      if method_name
        self.send(method_name, device, command, *args)
      else
        raise NoMethodError.new("No device method send_#{short_name(device)} for #{self.class.name})", "send_#{short_name(device)}")
      end
    end

    private
    def debug_log(msg)
      $stderr.puts msg if @debug
    end
    # Get up to one line of data from the device, or as much as can be gathered before the timeout, whichever is
    # lesser (i.e. sooner). Return any data collected.
    #
    # @param [IO::Socket] socket the socket to collect data from
    # @param [Integer] timeout (100) the time to wait for data in milliseconds
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
