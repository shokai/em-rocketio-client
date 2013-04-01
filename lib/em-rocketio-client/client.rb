module EventMachine
  module RocketIO
    class Client
      class Error < StandardError
      end

      include EventEmitter
      attr_reader :settings, :type, :io, :channel

      public
      def initialize(url, opt={:type => :websocket, :channel => nil})
        @url = url
        @type = opt[:type].to_sym
        @channel = opt[:channel] ? opt[:channel].to_s : nil
        @settings = nil
        @io = nil
        @ws_close_timer = nil
        get_settings
        self
      end

      private
      def get_settings
        url = "#{@url}/rocketio/settings"
        http = EM::HttpRequest.new(url).get
        http.callback do |res|
          begin
            @settings = JSON.parse res.response
            emit :__settings
          rescue => e
            emit :error, "#{e} (#{url})"
            EM::add_timer 10 do
              get_settings
            end
          end
        end
        http.errback do |e|
          if e.error == Errno::ECONNREFUSED
            emit :error, "connection refused (#{url})"
          else
            emit :error, "#{e.error} (#{url})"
          end
          EM::add_timer 10 do
            get_settings
          end
        end
      end

      public
      def connect
        this = self
        once :__settings do
          if @type == :websocket and @settings.include? 'websocket'
            @io = EM::WebSocketIO::Client.new(@settings['websocket']).connect
          elsif @type == :comet or @settings.include? 'comet'
            @io = EM::CometIO::Client.new(@settings['comet']).connect
            @type = :comet
          else
            raise Error, "cannnot found #{@type} IO"
          end
          @io.on :* do |event_name, *args|
            event_name = :__connect if event_name == :connect
            this.emit event_name, *args
          end
          this.on :__connect do
            this.io.push :__channel_id, this.channel
            this.emit :connect
          end
          if @type == :websocket
            @ws_close_timer = EM::add_timer 3 do
              close
              emit :error, "websocket port is not open"
              @type = :comet
              connect
            end
            once :connect do
              EM::cancel_timer @ws_close_timer if @ws_close_timer
              @ws_close_timer = nil
            end
          end
        end
        emit :__settings if @settings
        self
      end

      def close
        @io.close
      end

      def push(type, data={})
        @io.push type, data if @io
      end

      def method_missing(name, *args)
        @io.__send__ name, *args
      end

    end
  end
end
