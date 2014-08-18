module Mandrake
  module DSL
    # A class for building an expression by using the method_missing method
    # @example
    #   Oh = Class.new(Mandrake::DSL::Stringify)
    #   Oh.stringify.Mikey.hello('boy').to_s #=> "oh.Mikey.hello(\"boy\")"
    #   Oh.stringify.James.goodbye('man').to_s #=> "oh.James.goodbye(\"man\")"
    #   Oh.stringify.Mikey.hello('boy').and(Oh.stringify.James.goodbye('man')).to_s
    #     #=> "oh.Mikey.hello(\"boy\") && oh.James.goodbye(\"man\")"
    # @!visibility private
    class Stringify
      # @!visibility private
      def stringify
        self.class.stringify
      end
    
      # @!visibility private
      def self.stringify
        Stringify::Relation.new(self)
      end
    
      # @!visibility private
      class Relation
        # Defines a method for the relation
        # @param [String, Symbol] name
        # @yield block on which to base the method
        # @!visibility private
        def self.chain(name, &block)
          define_method(name){|*args| instance_exec(*args, &block); self; }
        end

        # @param [Class] klass
        # @!visibility private
        def initialize(klass)
          @class = klass
          reset_string
        end
    
        # Returns a string built by this class
        # @!visibility private
        def to_s
          @string
        end

        chain(:[])    {|*args|     @string << "[#{args.map(&:inspect) * ", "}]" }
        chain(:==)    {|value|     @string << " == #{value.inspect}" }
        chain(:and)   {|relation|  @string << " && " << relation.to_s }
        chain(:or)    {|relation|  @string << " || " << relation.to_s }
        chain(:method_missing) {|method_name, *args|
          @string << ".#{method_name}"
          @string << "(#{args.map(&:inspect) * ", "})" unless args.length.zero? }
        chain(:reset_string) { @string = "#{@class.name.downcase.split(/::/).last}" }
        alias equal ==
        alias eq equal
      end
    end
  end
end
