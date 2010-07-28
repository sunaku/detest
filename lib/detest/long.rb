# Provides long name aliases for Detest's default abbreviated vocabulary.

require 'detest'

module Detest
  short_to_long = {
    'T' => 'True',
    'F' => 'False',
    'N' => 'Nil',
    'E' => 'Error',
    'C' => 'Catch',
    'I' => 'Inform',
    'S' => 'Share',
    'D' => 'Describe',
  }

  short_to_long.each do |src, dst|
    instance_methods(false).grep(/^#{src}\b/).each do |short|
      long = short.to_s.sub(src, dst)
      alias_method long, short
    end
  end

  # for hooks
  Describe = D
end
