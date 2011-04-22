# -*- encoding: utf-8 -*-

gemspec = Gem::Specification.new do |s|
  s.name = %q{detest}
  s.version = "3.1.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Suraj N. Kurapati"]
  s.date = %q{2011-04-22}
  s.description = %q{Detest is an assertion testing library for [Ruby] that features a simple assertion vocabulary, instant debuggability of failures, and flexibility in composing tests.}
  s.executables = ["detest"]
  s.files = ["bin/detest", "lib/detest", "lib/detest/unit.rb", "lib/detest/inochi.rb", "lib/detest/long.rb", "lib/detest/auto.rb", "lib/detest/spec.rb", "lib/detest/mini.rb", "lib/detest.rb", "LICENSE", "man/man1/detest.1"]
  s.homepage = %q{http://snk.tuxfamily.org/lib/detest/}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.7.2}
  s.summary = %q{Assertion testing library for Ruby}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
system 'inochi', *gemspec.files
gemspec
