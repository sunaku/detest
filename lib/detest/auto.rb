# Provides painless, automatic configuration of Detest.
#
# Simply require() this file and Detest will be available for use anywhere
# in your program and will execute all tests before your program exits.

require 'detest'
include Detest

at_exit do
  Detest.start

  # reflect number of failures in exit status
  stats = Detest.stats
  fails = stats[:fail] + stats[:error]

  exit [fails, 255].min
end
