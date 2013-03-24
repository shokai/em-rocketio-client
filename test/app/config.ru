require 'rubygems'
require 'sinatra'
require 'sinatra/base'
$stdout.sync = true
require 'sinatra/rocketio'
require File.dirname(__FILE__)+'/main'

set :websocketio, :port => ENV['WS_PORT'].to_i

run TestApp
