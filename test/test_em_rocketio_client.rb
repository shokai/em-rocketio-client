require File.expand_path 'test_helper', File.dirname(__FILE__)

class TestEmRocketioClient < MiniTest::Unit::TestCase

  def setup
    App.start
  end

  def teardown
    App.stop
  end

  def test_websocket_to_comet
    ## websocket --> server --> comet
    post_data = {:time => Time.now.to_s, :msg => 'hello!!', :to => nil}
    res = nil
    res2 = nil
    EM::run do
      client = EM::RocketIO::Client.new(App.url, :type => :websocket).connect
      client.on :message do |data|
        res = data
        EM::add_timer 1 do
          EM::stop
        end
      end

      client.on :disconnect do
        EM::add_timer 1 do
          EM::stop
        end
      end

      client.on :connect do |session|
        client2 = EM::RocketIO::Client.new(App.url, :type => :comet).connect
        client2.on :connect do |session2|
          post_data['to'] = session2
          client.push :message, post_data
        end
        client2.on :message do |data|
          res2 = data
          client2.close
          client.close
          EM::add_timer 1 do
            EM::stop
          end
        end
      end

      EM::defer do
        50.times do
          break if res != nil
          sleep 0.1
        end
        client.close
      end
    end
    assert res2 != nil, 'server not respond'
    assert res2["time"] == post_data[:time]
    assert res2["msg"] == post_data[:msg]
    assert res == nil
  end

  def test_comet_to_websocket
    ## comet --> server --> websocket
    post_data = {:time => Time.now.to_s, :msg => 'hello!!', :to => nil}
    res = nil
    res2 = nil
    EM::run do
      client = EM::RocketIO::Client.new(App.url, :type => :comet).connect
      client.on :message do |data|
        res = data
        EM::add_timer 1 do
          EM::stop
        end
      end

      client.on :connect do |session|
        client2 = EM::RocketIO::Client.new(App.url, :type => :websocket).connect
        client2.on :connect do |session2|
          post_data['to'] = session2
          client.push :message, post_data
        end
        client2.on :message do |data|
          res2 = data
          client2.close
          client.close
          EM::add_timer 1 do
            EM::stop
          end
        end
      end

      EM::defer do
        50.times do
          break if res != nil
          sleep 0.1
        end
        client.close
        EM::add_timer 1 do
          EM::stop
        end
      end
    end
    assert res2 != nil, 'server not respond'
    assert res2["time"] == post_data[:time]
    assert res2["msg"] == post_data[:msg]
    assert res == nil
  end

end
