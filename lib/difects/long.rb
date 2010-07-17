# Provides long name aliases for DIFECTS's default abbreviated vocabulary.

require 'difects'

module DIFECTS
  short_to_long = {
    'D' => 'Describe',
    'T' => 'True',
    'F' => 'False',
    'E' => 'Error',
    'C' => 'Catch',
    'S' => 'Share',
    'I' => 'Inform',
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
