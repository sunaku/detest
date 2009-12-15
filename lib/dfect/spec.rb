# RSpec emulation layer.
#--
# Copyright protects this work.
# See LICENSE file for details.
#++

require 'dfect'

module Dfect
  alias describe D
  alias context  D
  alias it       D

  def before what, &block
    meth =
      case what
      when :each then :<
      when :all  then :<<
      else raise ArgumentError, what
      end

    send meth, &block
  end

  def after what, &block
    meth =
      case what
      when :each then :>
      when :all  then :>>
      else raise ArgumentError, what
      end

    send meth, &block
  end
end
