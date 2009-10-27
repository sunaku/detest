# RSpec emulation layer.
#--
# Copyright protects this work.
# See LICENSE file for details.
#++

require 'dfect'

module Kernel
  def describe *args, &block
    Dfect.D args.join(' '), &block
  end

  alias context describe
  alias it      describe

  def before what, &block
    meth =
      case what
      when :each then :<
      when :all  then :<<
      else raise ArgumentError, what
      end

    Dfect.send meth, &block
  end

  def after what, &block
    meth =
      case what
      when :each then :>
      when :all  then :>>
      else raise ArgumentError, what
      end

    Dfect.send meth, &block
  end
end
