require File.expand_path("../../lib/mandrake", __FILE__)
require 'bundler' unless defined?(Bundler)
Bundler.require(:test)

class OptionalMiddleware
  def initialize(app, options = {}, &block)
    @app = app
    @options = options
    @block = true if block_given?
  end

  def call(env)
    response = @app.call(env)
    response[1].merge!("Options" => @options.inspect, "Block" => @block.inspect)
    response
  end
end

class NothingMiddleware
  def initialize(app)
    @app = app
  end
  def call(env)
    @@env = env
    response = @app.call(env)
    response
  end
  def self.env
    @@env
  end
end

class Dummy
  def initialize(app)
    @app = app
  end

  def call(env)
    [200, {}, ["YAY!"]]
  end
end

def app
  @app
end

def rack_builder(&block)
  Rack::Lint.new Rack::Builder.new(&block)
end

def builder(&block)
  Rack::Lint.new Mandrake::Builder.new(&block)
end
  
def builder_to_app(&block)
  Rack::Lint.new Mandrake::Builder.new(&block).to_app
end

class TestApp
  def call(env)
    [200, {"Content-Type" => "text/plain"}, ["test app"]]
  end
end
