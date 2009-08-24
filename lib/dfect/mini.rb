# MiniTest emulation layer.
#--
# Copyright protects this work.
# See LICENSE file for details.
#++

require 'dfect'
require 'dfect/unit'
require 'dfect/spec'

module Kernel
  instance_methods(false).each do |meth|
    if meth =~ /^assert_not/
      alias_method 'refute' + $', meth
    end
  end
end

{
  :must => :assert,
  :wont => :refute,
}.
each do |outer, inner|
  file, line = __FILE__, __LINE__ ; eval %{
    class Object
      def #{outer}_be_close_to other, message = nil
        #{inner}_in_delta self, other, nil, message
      end

      def #{outer}_be_empty message = nil
        #{inner}_empty self, message
      end

      def #{outer}_be_instance_of _class, message = nil
        #{inner}_instance_of _class, self, message
      end

      def #{outer}_be_kind_of _class, message = nil
        #{inner}_kind_of _class, self, message
      end

      def #{outer}_be_nil message = nil
        #{inner}_nil self, message
      end

      def #{outer}_be_same_as other, message = nil
        #{inner}_same self, other, message
      end

      def #{outer}_be_within_delta other, delta = nil, message = nil
        #{inner}_in_delta self, other, delta, message
      end

      alias #{outer}_be_within_epsilon #{outer}_be_within_delta

      def #{outer}_equal expected, message = nil
        #{inner}_equal expected, self, message
      end

      def #{outer}_include item, message = nil
        #{inner}_include item, self, message
      end

      def #{outer}_match pattern, message = nil
        #{inner}_match pattern, self, message
      end

      def #{outer}_raise *args, &block
        #{inner}_raise(*args, &block)
      end

      def #{outer}_respond_to query, message = nil
        #{inner}_respond_to self, query, message
      end

      def #{outer}_send query, *args
        #{inner}_send self, query, *args
      end
    end

    class Proc
      def #{outer}_raise *args
        #{inner}_raise(*args, &self)
      end

      def #{outer}_throw symbol, message = nil
        #{inner}_throw symbol, message, &self
      end
    end
  }, binding, file, line
end
