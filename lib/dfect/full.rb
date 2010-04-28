# Provides full name aliases for Dfect's default abbreviated vocabulary.

require 'dfect'

module Dfect
  full_names = {
    'D' => 'Describe',
    'T' => 'True',
    'F' => 'False',
    'E' => 'Error',
    'C' => 'Catch',
    'S' => 'Share',
    'L' => 'Log',
  }

  instance_methods(false).each do |meth_name|
    if full_name = meth_name.to_s.sub!(/^[A-Z]/) {|abbr| full_names[abbr] }
      alias_method full_name, meth_name
    end
  end

  # for hooks
  Describe = D
end
