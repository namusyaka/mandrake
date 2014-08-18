require 'mandrake/builder'

module Mandrake
  # Mandrake::Middleware can quickly be used on your application
  # @example
  #   use Mandrake::Middleware do
  #     use Rack::ETag, if: request.path_info.start_with?("/public")
  #   end
  module Middleware
    def self.new(app, &block)
      builder = Mandrake::Builder.new
      builder.instance_eval(&block)
      builder.run(app)
      builder.to_app
    end
  end
end
