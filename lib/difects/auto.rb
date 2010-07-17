# Provides painless, automatic configuration of DIFECTS.
#
# Simply require() this file and DIFECTS will be available for use anywhere
# in your program and will execute all tests before your program exits.

require 'difects'
include DIFECTS

at_exit do
  DIFECTS.start

  # reflect number of failures in exit status
  stats = DIFECTS.stats
  fails = stats[:fail] + stats[:error]

  exit [fails, 255].min
end
