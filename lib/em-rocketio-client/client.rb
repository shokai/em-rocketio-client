module EventMachine
  module RocketIO
    class Client
      class Error < StandardError
      end

      include EventEmitter
      attr_reader :settings, :type, :io

      def initialize(url, opt={:type => :websocket})
        @settings = JSON.parse HTTParty.get("#{url}/rocketio/settings").body
        type = opt[:type].to_sym
        if type == :websocket and @settings.include? 'websocket'
          @type = :websocket
          @io = EM::WebSocketIO::Client.new @settings['websocket']
        elsif type == :comet or @settings.include? 'comet'
          @type = :comet
          @io = EM::CometIO::Client.new @settings['comet']
        else
          raise Error, "cannot find #{type} IO #{url}"
        end
        this = self
        if @io
          @io.on :* do |event_name, *args|
            this.emit event_name, *args
          end
        end
        self
      end

      def connect
        @io.connect
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
