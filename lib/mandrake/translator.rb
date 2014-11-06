require 'mandrake/dsl'

module Mandrake
  # A class for being delegated from the Mandrake::Builder class
  # @!visibility private
  class Translator
    # Construcsts an instance of Mandrake::Translator
    def initialize
      @middlewares = []
    end

    # @overload Rack::Builder#use(middleware, *args, options = {})
    # @param [Hash] options The options can be included :if and :unless keys
    # @return [Array] All registered middlewares
    def use(middleware, *args, **options, &block)
      parameters = extract_parameters_from(options)
      @middlewares << Any.new(middleware, (options.empty? ? args : (args << options)), parameters, block)
    end

    # Translates middlewares to compatible data with Rack::Builder's processing
    # @return [Array]
    def translate
      @middlewares.map do |middleware|
        if   middleware.conditional?
        then proc{|app| Wrapper.new(app, middleware.construct(app), middleware.condition) }
        else proc{|app| middleware.construct(app) }
        end
      end
    end

    # The string builder for building an expression
    # @see Mandrake::DSL::Env
    def env
      DSL::Env.stringify
    end

    # The string builder for building an expression
    # @see Mandrake::DSL::Request
    def request
      DSL::Request.stringify
    end

    # Extracts :if and :unless pairs from options
    # @!visibility private
    def extract_parameters_from(options)
      [:if, :unless].inject({}) do |parameters, key|
        expression = parameters[key] = options.delete(key) if options[key]
        if expression.instance_of?(Proc) && !expression.lambda?
          parameters[key] = instance_eval(&expression) 
        end
        parameters
      end
    end

    private :extract_parameters_from

    # A class for use in Mandrake::Translator#translate
    # @!visibility private
    class Any < Struct.new(:klass, :arguments, :parameters, :block)
      # @!visibility private
      def condition
        @condition ||=
          begin
            expressions = []
            expressions << DSL::If.new(parameters[:if]) if parameters[:if]
            expressions << DSL::Unless.new(parameters[:unless]) if parameters[:unless]
            expressions.inject(:+)
          end
      end

      # @!visibility private
      def construct(app)
        klass.new(app, *arguments, &block)
      end

      # @!visibility private
      def conditional?
        !!condition
      end
    end

    # A wrapper class for conditional middleware which is containing the validator
    # @!visibility private
    class Wrapper
      attr_accessor :env, :request
  
      # @!visibility private
      def initialize(app, middleware, condition)
        @app = app
        @middleware = middleware
        add_validator(condition)
      end
  
      # @param [Hash] env
      # @!visibility private
      def call(env)
        @env = env
        @request = Rack::Request.new(@env)
        valid? ? @middleware.call(env) : @app.call(env)
      end
  
      # @param [String, Proc] condition
      # @!visibility private
      def add_validator(condition)
        code = condition.code
        if code.instance_of?(Proc) && code.lambda?
          singleton_class.send(:define_method, :valid?, &code)
        else
          instance_eval("def valid?; #{condition} end")
        end
      end

      private :add_validator
    end
  end
end
