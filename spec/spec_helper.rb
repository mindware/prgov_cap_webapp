RACK_ENV = 'test' unless defined?(RACK_ENV)
require File.expand_path(File.dirname(__FILE__) + "/../config/boot")
require 'rr'

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
end

# You can use this method to custom specify a Rack app
# you want rack-test to invoke:
#
#   app PRgovCAPWebApp::App
#   app PRgovCAPWebApp::App.tap { |a| }
#   app(PRgovCAPWebApp::App) do
#     set :foo, :bar
#   end
#
def app(app = nil, &blk)
  @app ||= block_given? ? app.instance_eval(&blk) : app
  @app ||= Padrino.application
end
