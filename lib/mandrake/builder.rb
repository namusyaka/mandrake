require 'mandrake/translator'
require 'rack'
require 'forwardable'

module Mandrake
  # Mandrake::Builder based on Rack::Builder
  # It adds :if and :unless options to the `use` method,
  # and enables conditional expression builders such as `env` and `request`
  # @example
  #   Mandrake::Builder.new do
  #     use Rack::Deflater, if:     request.path_info.start_with?("/deflater")
  #     use Rack::ETag,     unless: request.path_info.end_with?("etag")
  #     run ->(env){ [200, {'Content-Type' => 'text/plain'}, ["Hello World"]] }
  #   end
  class Builder < Rack::Builder
    extend Forwardable
    def_delegators :translator, :use, :request, :env

    # Converts to application by using Mandrake::Translator
    def to_app
      app = @map ? generate_map(@run, @map) : @run
      fail "missing run or map statement" unless app
      app = translator.translate.reverse.inject(app) do |application, middleware|
        middleware[application]
      end
      @warmup.call(app) if @warmup
      app
    end

    # This method is for delegating methods
    # Returns an instance of Mandrake::Translator for use in delegation and to_app
    # @return [Mandrake::Translator]
    def translator
      @translator ||= Translator.new
    end

    private :translator

    if Rack.release <= "1.5"
      def warmup(prc=nil, &block)
        @warmup = prc || block
      end

      def generate_map(default_app, mapping)
        mapped = default_app ? {'/' => default_app} : {}
        mapping.each { |r,b| mapped[r] = self.class.new(default_app, &b).to_app }
        Rack::URLMap.new(mapped)
      end
    end
  end
end
