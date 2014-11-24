#!/usr/bin/env rackup
# encoding: utf-8

require 'redis'
# Include the redis-store gem for sessions storage
require 'redis-rack'
require 'rack/session/redis'
require 'rest_client'

# This file can be used to start Padrino,
# just execute it from the command line.

require File.expand_path("../config/boot.rb", __FILE__)

# Load Dotenv!
Dotenv.load

# Enable primary Redis for our validated data
# this is mainly for data that persists al ittle longer
$redis = Redis.new(:host => ENV['REDIS_SERVER'],
                   :port => ENV['REDIS_PORT'],
                   :db   => ENV['REDIS_DB'],
                   :password => ENV['REDIS_SECRET'])


# Enable secondary Redis connection for temporary session handling
# using Redis via Redis-rack sessions library.
use Rack::Session::Redis, :redis_server => "redis://:#{ENV['REDIS_SECRET']}@#{ENV['REDIS_SERVER']}:#{ENV['REDIS_PORT']}/#{ENV['REDIS_SESSION_DB']}/#{ENV['REDIS_NAMESPACE']}:session"


# Enable reCAPTCHA middleware.
use Rack::Recaptcha, :public_key => ENV['RECAPTCHA_PUBLIC_KEY'], :private_key => ENV['RECAPTCHA_PRIVATE_KEY']

run Padrino.application
