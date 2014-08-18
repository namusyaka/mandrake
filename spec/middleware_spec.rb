require 'spec_helper'

describe Mandrake::Middleware do
  it "can be executed in Rack::Builder" do
    app = rack_builder do
      use Mandrake::Middleware do
        use Dummy, if: request.path_info.start_with?("/public")
      end
      run lambda { |env| [200, {"Content-Type" => "text/plain"}, ['Hi Boss']] }
    end
    expect(Rack::MockRequest.new(app).get("/").body.to_s).to eq 'Hi Boss'
    expect(Rack::MockRequest.new(app).get("/public").body.to_s).to eq 'YAY!'
  end
end
