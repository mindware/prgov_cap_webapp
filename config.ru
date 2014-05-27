#!/usr/bin/env rackup
# encoding: utf-8

# This file can be used to start Padrino,
# just execute it from the command line.

require File.expand_path("../config/boot.rb", __FILE__)

# Load Dotenv!
Dotenv.load

# Enable session handling using Redis via Moneta library.
use Rack::Session::Moneta, key: 'session.id', store: :Redis

# Enable reCAPTCHA middleware.
use Rack::Recaptcha, :public_key => ENV['RECAPTCHA_PUBLIC_KEY'], :private_key => ENV['RECAPTCHA_PRIVATE_KEY']

run Padrino.application
