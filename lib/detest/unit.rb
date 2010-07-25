# Test::Unit emulation layer.

require 'detest'

module Detest
  alias test      D
  alias setup     <
  alias setup!    <<
  alias teardown  >
  alias teardown! >>

  [
    [:assert,     nil,  nil   ],
    [:assert_not, '!',  'not '],
  ].
  each do |prefix, polarity, action|
    #
    # XXX: using eval() because Ruby 1.8 does
    #      not support default values and
    #      block parameters in define_method()
    #
    file, line = __FILE__, __LINE__ ; module_eval %{
      alias #{prefix} T#{polarity}
      alias #{prefix} T#{polarity}

      def #{prefix}_empty collection, message = nil
        message ||= 'collection must #{action}be empty'
        T#{polarity}(message) { collection.empty? }
      end

      def #{prefix}_equal expected, actual, message = nil
        message ||= 'actual must #{action}equal expected'
        T#{polarity}(message) { actual == expected }
      end

      def #{prefix}_in_delta expected, actual, delta = nil, message = nil
        message ||= 'actual must #{action}be within delta of expected'
        delta   ||= 0.001

        T#{polarity}(message) do
          Math.abs(expected - actual) <= Math.abs(delta)
        end
      end

      alias #{prefix}_in_epsilon #{prefix}_in_delta

      def #{prefix}_include item, collection, message = nil
        message ||= 'collection must #{action}include item'
        T#{polarity}(messsage) { collection.include? item }
      end

      def #{prefix}_instance_of klass, object, message = nil
        message ||= 'object must #{action}be an instance of class'
        T#{polarity}(message) { object.instance_of? klass }
      end

      def #{prefix}_kind_of klass, object, message = nil
        message ||= 'object must #{action}be a kind of class'
        T#{polarity}(message) { object.kind_of? klass }
      end

      def #{prefix}_nil object, message = nil
        message ||= 'object must #{action}be nil'
        T#{polarity}(message) { object == nil }
      end

      def #{prefix}_match pattern, string, message = nil
        message ||= 'string must #{action}match pattern'
        T#{polarity}(message) { string =~ pattern }
      end

      def #{prefix}_same expected, actual, message = nil
        message ||= 'actual must #{action}be same as expected'
        T#{polarity}(message) { actual.equal? expected }
      end

      def #{prefix}_operator object, operator, operand, message = nil
        message ||= 'object must #{action}support operator with operand'
        T#{polarity} { object.__send__ operator, operand }
      end

      def #{prefix}_raise *args, &block
        E#{polarity}(args.pop, *args, &block)
      end

      def #{prefix}_respond_to object, query, message = nil
        message ||= 'object must #{action}respond to query'
        T#{polarity}(message) { object.respond_to? query }
      end

      def #{prefix}_throw symbol, message = nil, &block
        C#{polarity}(message, symbol, &block)
      end

      def #{prefix}_send object, query, *args
        response = object.__send__(query, *args)
        T#{polarity} { response }
      end
    }, file, line
  end
end
