module EventMachine
  module RocketIO
    class Client
      class Error < StandardError
      end

      include EventEmitter
      attr_reader :settings, :type, :io

      def initialize(url, opt={:type => :websocket})
        http = EM::HttpRequest.new("#{url}/rocketio/settings").get
        http.callback do |res|
          begin
            @settings = JSON.parse res.response
            emit :__settings
          rescue => e
            emit :error, e
          end
        end
        http.errback do |err|
          emit :error, err
        end
        @settings = nil
        @type = opt[:type].to_sym
        @io = nil
        @ws_close_timer = nil
        self
      end

      def connect
        this = self
        once :__settings do
          if @type == :websocket and @settings.include? 'websocket'
            @io = EM::WebSocketIO::Client.new(@settings['websocket']).connect
            @type = :websocket
          elsif @type == :comet or @settings.include? 'comet'
            @io = EM::CometIO::Client.new(@settings['comet']).connect
            @type = :comet
          else
            raise Error, "cannnot found #{@type} IO"
          end
          @io.on :* do |event_name, *args|
            this.emit event_name, *args
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
        @io.push type, data
      end

      def method_missing(name, *args)
        @io.__send__ name, *args
      end

    end
  end
end
