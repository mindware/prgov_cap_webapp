#!/usr/bin/env rackup
# encoding: utf-8

# This file can be used to start Padrino,
# just execute it from the command line.

require File.expand_path("../config/boot.rb", __FILE__)

# Enable session handling using Redis via Moneta library.
use Rack::Session::Moneta, store: :Redis

run Padrino.application
