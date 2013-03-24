#!/usr/bin/env ruby
$:.unshift File.expand_path '../lib', File.dirname(__FILE__)
require 'rubygems'
require 'em-rocketio-client'

name = `whoami`.strip || 'shokai'
url = ARGV.shift || 'http://localhost:5000'
type = ARGV.shift || :websocket

EM::run do
  io = EM::RocketIO::Client.new(url, :type => type).connect
  # io = EM::RocketIO::Client.new('http://localhost:5000', :type => :comet).connect

  io.on :connect do |session|
    puts "#{io.type} connect!! (sessin_id:#{session})"
  end

  io.on :disconnect do
    puts "#{io.type} disconnect"
  end

  io.on :chat do |data|
    puts "<#{data['name']}> #{data['message']}"
  end

  io.on :error do |err|
    STDERR.puts err
  end

  EM::defer do
    loop do
      line = STDIN.gets.strip
      next if line.empty?
      io.push :chat, {:message => line, :name => name}
    end
  end
end
