# Test::Unit emulation layer.
#--
# Copyright protects this work.
# See LICENSE file for details.
#++

require 'dfect'

module Kernel
  def setup &block
    Dfect.<(&block)
  end

  def teardown &block
    Dfect.>(&block)
  end

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
    file, line = __FILE__, __LINE__ ; eval %{
      def #{prefix} boolean, message = nil
        Dfect.T#{polarity}(message) { boolean }
      end

      def #{prefix}_block message = nil, &block
        Dfect.T#{polarity}(&block)
      end

      def #{prefix}_empty collection, message = nil
        message ||= 'collection must #{action}be empty'
        Dfect.T#{polarity}(message) { collection.empty? }
      end

      def #{prefix}_equal expected, actual, message = nil
        message ||= 'actual must #{action}equal expected'
        Dfect.T#{polarity}(message) { actual == expected }
      end

      def #{prefix}_in_delta expected, actual, delta = nil, message = nil
        message ||= 'actual must #{action}be within delta of expected'
        delta   ||= 0.001

        Dfect.T#{polarity}(message) { Math.abs(expected - actual) <= Math.abs(delta) }
      end

      alias #{prefix}_in_epsilon #{prefix}_in_delta

      def #{prefix}_include item, collection, message = nil
        message ||= 'collection must #{action}include item'
        Dfect.T#{polarity}(messsage) { collection.include? item }
      end

      def #{prefix}_instance_of _class, object, message = nil
        message ||= 'object must #{action}be an instance of class'
        Dfect.T#{polarity}(message) { object.instance_of? _class }
      end

      def #{prefix}_kind_of _class, object, message = nil
        message ||= 'object must #{action}be a kind of class'
        Dfect.T#{polarity}(message) { object.kind_of? _class }
      end

      def #{prefix}_nil object, message = nil
        message ||= 'object must #{action}be nil'
        Dfect.T#{polarity}(message) { object == nil }
      end

      def #{prefix}_match pattern, string, message = nil
        message ||= 'string must #{action}match pattern'
        Dfect.T#{polarity}(message) { string =~ pattern }
      end

      def #{prefix}_same expected, actual, message = nil
        message ||= 'actual must #{action}be same as expected'
        Dfect.T#{polarity}(message) { actual.equal? expected }
      end

      def #{prefix}_operator object, operator, operand, message = nil
        message ||= 'object must #{action}support operator with operand'
        Dfect.T#{polarity} { object.__send__ operator, operand }
      end

      def #{prefix}_raise *args, &block
        Dfect.E#{polarity}(args.pop, *args, &block)
      end

      def #{prefix}_respond_to object, query, message = nil
        message ||= 'object must #{action}respond to query'
        Dfect.T#{polarity}(message) { object.respond_to? query }
      end

      def #{prefix}_throw symbol, message = nil, &block
        Dfect.C#{polarity}(message, symbol, &block)
      end

      def #{prefix}_send object, query, *args
        response = object.__send__(query, *args)
        Dfect.T#{polarity} { response }
      end
    }, binding, file, line
  end
end
