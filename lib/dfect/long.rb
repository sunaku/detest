# Provides long name aliases for Dfect's default abbreviated vocabulary.

require 'dfect'

module Dfect
  short_to_long = {
    'D' => 'Describe',
    'T' => 'True',
    'F' => 'False',
    'E' => 'Error',
    'C' => 'Catch',
    'S' => 'Share',
    'I' => 'Inform',
  }

  short_names = instance_methods(false).grep(/^[#{short_to_long.keys.join}]\b/)

  short_to_long.each do |prefix, long|
    short_names.grep(/^#{prefix}/).each do |short|
      alias_method short.to_s.sub(prefix, long), short
    end
  end

  # for hooks
  Describe = D
end
