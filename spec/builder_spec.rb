require 'spec_helper'
require 'rack/builder'
require 'rack/lint'
require 'rack/mock'
require 'rack/showexceptions'
require 'rack/urlmap'

describe Mandrake::Builder do
  it "supports mapping" do
    app = builder_to_app do
      map '/' do |outer_env|
        run lambda { |inner_env| [200, {"Content-Type" => "text/plain"}, ['root']] }
      end
      map '/sub' do
        run lambda { |inner_env| [200, {"Content-Type" => "text/plain"}, ['sub']] }
      end
    end
    expect(Rack::MockRequest.new(app).get("/").body.to_s).to eq 'root'
    expect(Rack::MockRequest.new(app).get("/sub").body.to_s).to eq 'sub'
  end

  it "doesn't dupe env even when mapping" do
    app = builder_to_app do
      use NothingMiddleware
      map '/' do |outer_env|
        run lambda { |inner_env|
          inner_env['new_key'] = 'new_value'
          [200, {"Content-Type" => "text/plain"}, ['root']]
        }
      end
    end
    expect(Rack::MockRequest.new(app).get("/").body.to_s).to eq 'root'
    expect(NothingMiddleware.env['new_key']).to eq 'new_value'
  end

  it "chains apps by default" do
    app = builder_to_app do
      use Rack::ShowExceptions
      run lambda { |env| raise "bzzzt" }
    end

    expect(Rack::MockRequest.new(app).get("/")).to be_server_error
    expect(Rack::MockRequest.new(app).get("/")).to be_server_error
    expect(Rack::MockRequest.new(app).get("/")).to be_server_error
  end

  it "has implicit #to_app" do
    app = builder do
      use Rack::ShowExceptions
      run lambda { |env| raise "bzzzt" }
    end

    expect(Rack::MockRequest.new(app).get("/")).to be_server_error
    expect(Rack::MockRequest.new(app).get("/")).to be_server_error
    expect(Rack::MockRequest.new(app).get("/")).to be_server_error
  end

  it "supports blocks on use" do
    app = builder do
      use Rack::ShowExceptions
      use Rack::Auth::Basic do |username, password|
        'secret' == password
      end

      run lambda { |env| [200, {"Content-Type" => "text/plain"}, ['Hi Boss']] }
    end

    response = Rack::MockRequest.new(app).get("/")
    expect(response).to be_client_error
    expect(response.status).to eq 401

    # with auth...
    response = Rack::MockRequest.new(app).get("/",
        'HTTP_AUTHORIZATION' => 'Basic ' + ["joe:secret"].pack("m*"))
    expect(response.status).to eq 200
    expect(response.body.to_s).to eq 'Hi Boss'
  end

  it "has explicit #to_app" do
    app = builder do
      use Rack::ShowExceptions
      run lambda { |env| raise "bzzzt" }
    end

    expect(Rack::MockRequest.new(app).get("/")).to be_server_error
    expect(Rack::MockRequest.new(app).get("/")).to be_server_error
    expect(Rack::MockRequest.new(app).get("/")).to be_server_error
  end

  it "can mix map and run for endpoints" do
    app = builder do
      map '/sub' do
        run lambda { |inner_env| [200, {"Content-Type" => "text/plain"}, ['sub']] }
      end
      run lambda { |inner_env| [200, {"Content-Type" => "text/plain"}, ['root']] }
    end

    expect(Rack::MockRequest.new(app).get("/").body.to_s).to eq 'root'
    expect(Rack::MockRequest.new(app).get("/sub").body.to_s).to eq 'sub'
  end

  it "accepts middleware-only map blocks" do
    app = builder do
      map('/foo') { use Rack::ShowExceptions }
      run lambda { |env| raise "bzzzt" }
    end

    expect { Rack::MockRequest.new(app).get("/") }.to raise_error(RuntimeError)
    expect(Rack::MockRequest.new(app).get("/foo")).to be_server_error
  end

  it "yields the generated app to a block for warmup" do
    warmed_up_app = nil

    app = Mandrake::Builder.new do
      warmup { |a| warmed_up_app = a }
      run lambda { |env| [200, {}, []] }
    end.to_app

    expect(warmed_up_app).to equal app
  end

  it "initialize apps once" do
    app = builder do
      class AppClass
        def initialize
          @called = 0
        end
        def call(env)
          raise "bzzzt"  if @called > 0
        @called += 1
          [200, {'Content-Type' => 'text/plain'}, ['OK']]
        end
      end

      use Rack::ShowExceptions
      run AppClass.new
    end

    expect(Rack::MockRequest.new(app).get("/").status).to eq 200
    expect(Rack::MockRequest.new(app).get("/")).to be_server_error
  end

  it "allows use after run" do
    app = builder do
      run lambda { |env| raise "bzzzt" }
      use Rack::ShowExceptions
    end

    expect(Rack::MockRequest.new(app).get("/")).to be_server_error
    expect(Rack::MockRequest.new(app).get("/")).to be_server_error
    expect(Rack::MockRequest.new(app).get("/")).to be_server_error
  end

  it 'complains about a missing run' do
    expect { Rack::Lint.new Mandrake::Builder.app { use Rack::ShowExceptions }}.to raise_error(RuntimeError)
  end

  describe "parse_file" do
    def config_file(name)
      File.join(File.dirname(__FILE__), 'builder', name)
    end

    it "parses commented options" do
      app, options = Mandrake::Builder.parse_file config_file('options.ru')
      expect(Rack::MockRequest.new(app).get("/").body.to_s).to eq 'OK'
    end

    it "removes __END__ before evaluating app" do
      app, _ = Mandrake::Builder.parse_file config_file('end.ru')
      expect(Rack::MockRequest.new(app).get("/").body.to_s).to eq 'OK'
    end

    it "supports multi-line comments" do
      expect { Mandrake::Builder.parse_file config_file('comment.ru') }.not_to raise_error
    end

    it "requires anything not ending in .ru" do
      $: << File.dirname(__FILE__)
      app, * = Mandrake::Builder.parse_file 'builder/anything'
      expect(Rack::MockRequest.new(app).get("/").body.to_s).to eq 'OK'
      $:.pop
    end

    it "sets __LINE__ correctly" do
      app, _ = Mandrake::Builder.parse_file config_file('line.ru')
      expect(Rack::MockRequest.new(app).get("/").body.to_s).to eq '1'
    end
  end

  describe 'new_from_string' do
    it "builds a rack app from string" do
      app, = Mandrake::Builder.new_from_string "run lambda{|env| [200, {'Content-Type' => 'text/plane'}, ['OK']] }"
      expect(Rack::MockRequest.new(app).get("/").body.to_s).to eq 'OK'
    end
  end

  describe 'conditional builder' do
    it 'support request and env DSL on block' do
      app = builder do
        _env = env
        run lambda { |env| [200, {"Content-Type" => "text/plain"}, [request.to_s << _env.to_s]] }
      end
      expect(Rack::MockRequest.new(app).get("/").body.to_s).to eq 'requestenv'
    end

    it 'support :if option on use' do
      app = builder do
        use Dummy, if: request.path_info.start_with?("/public")
        run lambda { |env| [200, {"Content-Type" => "text/plain"}, ['Hi Boss']] }
      end
      expect(Rack::MockRequest.new(app).get("/").body.to_s).to eq 'Hi Boss'
      expect(Rack::MockRequest.new(app).get("/public").body.to_s).to eq 'YAY!'
    end

    it 'support :unless option on use' do
      app = builder do
        use Dummy, unless: request.path_info.start_with?("/public")
        run lambda { |env| [200, {"Content-Type" => "text/plain"}, ['Hi Boss']] }
      end
      expect(Rack::MockRequest.new(app).get("/").body.to_s).to eq 'YAY!'
      expect(Rack::MockRequest.new(app).get("/public").body.to_s).to eq 'Hi Boss'
    end

    it 'allow to pass proc to :if and :unless options' do
      app = builder do
        use Dummy, if: proc{ request.path_info.start_with?("/public") }
        run lambda { |env| [200, {"Content-Type" => "text/plain"}, ['Hi Boss']] }
      end
      expect(Rack::MockRequest.new(app).get("/").body.to_s).to eq 'Hi Boss'
      expect(Rack::MockRequest.new(app).get("/public").body.to_s).to eq 'YAY!'
    end

    it 'allow to pass lambda to :if and :unless options' do
      app = builder do
        use Dummy, if: ->{ request.path_info.start_with?("/public") }
        run lambda { |env| [200, {"Content-Type" => "text/plain"}, ['Hi Boss']] }
      end
      expect(Rack::MockRequest.new(app).get("/").body.to_s).to eq 'Hi Boss'
      expect(Rack::MockRequest.new(app).get("/public").body.to_s).to eq 'YAY!'
    end

    it 'can be set the arguments to #use' do
      app = builder do
        use OptionalMiddleware, hey: true do
          "hey"
        end
        use Dummy, if: env["REQUEST_METHOD"] == "POST"
        run lambda { |env| [200, {"Content-Type" => "text/plain"}, ['Hi Boss']] }
      end
      response = Rack::MockRequest.new(app).get("/public")
      expect(response.headers["Options"]).to be_an_instance_of(String)
      expect(response.headers["Block"]).to be_an_instance_of(String)
      expect(response.body.to_s).to eq 'Hi Boss'
    end
  end
end
