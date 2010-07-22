# Provides painless, automatic configuration of Dfect.
#
# Simply require() this file and Dfect will be available for use anywhere
# in your program and will execute all tests before your program exits.

require 'dfect'

class Object
  include Dfect
end

at_exit do
  Dfect.run

  # reflect number of failures in exit status
  stats = Dfect.stats
  fails = stats[:fail] + stats[:error]
  exit [fails, 255].min
end
