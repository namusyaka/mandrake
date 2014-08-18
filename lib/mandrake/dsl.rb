require 'mandrake/dsl/stringify'
require 'mandrake/dsl/conditional_expression'

module Mandrake
  # A module as namespace for defining DSL classes
  # @!visibility private
  module DSL
    Env = Class.new(Stringify)
    Request = Class.new(Stringify)
  end
end
