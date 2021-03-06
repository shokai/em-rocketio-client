em-rocketio-client
==================
[Sinatra RocketIO](https://github.com/shokai/sinatra-rocketio) Client for eventmachine

* https://github.com/shokai/em-rocketio-client

Installation
------------

    % gem install em-rocketio-client


Usage
-----

```ruby
require 'eventmachine'
require 'em-rocketio-client'

EM::run do
  io = EM::RocketIO::Client.new('http://localhost:5000').connect
  # io = EM::RocketIO::Client.new('http://localhost:5000', :type => :comet).connect
  # io = EM::RocketIO::Client.new('http://localhost:5000', :channel => '1').connect
  io.on :connect do
    puts "#{io.type} connect!! (sessin_id:#{io.session})"
  end

  io.on :disconnect do
    puts "#{io.type} disconnect"
  end

  io.on :error do |err|
    STDERR.puts err
  end

  ## regist receive "chat" event
  io.on :chat do |data|
    puts "#{data['name']} - #{data['message']}"
  end

  ## push "chat" event to Server
  EM::add_periodic_timer 10 do
    io.push :chat, {:message => Time.now.to_s, :name => 'clock'}
  end
end
```


Sample
------

start [chat server](https://github.com/shokai/rocketio-chat-sample)

    % git clone git://github.com/shokai/sinatra-rocketio.git
    % cd sinatra-rocketio
    % bundle install
    % cd sample/classic_style
    % rackup config.ru -p 5000

=> http://localhost:5000


sample chat client

    % ruby sample/cui_chat_client.rb
    % ruby sample/cui_chat_client.rb http://localhost:5000 comet
    % ruby sample/cui_chat_client.rb http://localhost:5000 websocket


Test
----

    % gem install bundler
    % bundle install

start server

    % export PORT=5000
    % export WS_PORT=9000
    % rake test_server

run test

    % rake test


Contributing
------------

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
