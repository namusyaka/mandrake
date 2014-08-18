module Mandrake
  module DSL
    # A class for building conditional expressions
    # @example
    #  cond1 = Mandrake::DSL::If.new('env["PATH_INFO"] == "/"')
    #  cond2 = Mandrake::DSL::Unless.new('env["REQUEST_METHOD"] == "GET"')
    #  cond1 + cond2       #=> '(env["PATH_INFO"] == "/") && !(env["REQUEST_METHOD"] == "GET")'
    #  cond1.concat(cond2) #=> '(env["PATH_INFO"] == "/") && !(env["REQUEST_METHOD"] == "GET")'
    #  cond1               #=> '(env["PATH_INFO"] == "/") && !(env["REQUEST_METHOD"] == "GET")'
    # @!visibility private
    class ConditionalExpression
      attr_accessor :code

      # @!visibility private
      def self.expression
        @expression
      end

      # @param [String] text
      # @!visibility private
      def self.template(text)
        @expression ||= text
      end

      # @param [Mandrake::DSL::Stringify::Relation, Proc] code
      # @!visibility private
      def initialize(code)
        @code = code
      end

      # @param [Mandrake::DSL::ConditonalExpression] other_expression
      # @!visibility private
      def +(other_expression)
        expression + " && " + other_expression.to_s
      end

      # Concatenates an other expression with self
      # @param [Mandrake::DSL::ConditonalExpression] other_expression
      # @!visibility private
      def concat(other_expression)
        @expression = send(:+, other_expression)
      end

      # @!visibility private
      def expression
        @expression ||= self.class.expression.gsub(/{:condition:}/, @code.to_s)
      end

      alias to_s expression
    end

    # @!visibility private
    class If < ConditionalExpression
      template "({:condition:})"
    end

    # @!visibility private
    class Unless < ConditionalExpression
      template "!({:condition:})"
    end
  end
end
