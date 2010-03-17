require 'dfect/inochi'

unless defined? Dfect::INOCHI
  fail "Dfect module must be established by Inochi"
end

Dfect::INOCHI.each do |param, value|
  const = param.to_s.upcase

  unless Dfect.const_defined? const
    fail "Dfect::#{const} must be established by Inochi"
  end

  unless Dfect.const_get(const) == value
    fail "Dfect::#{const} is not what Inochi established"
  end
end
