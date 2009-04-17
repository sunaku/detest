#--
# Copyright 2009 Suraj N. Kurapati
# See the LICENSE file for details.
#++

require 'dfect/auto'

D 'T()' do
  T { true }
  T { !false }
  T { !nil }

  T { 0 }
  T { 1 }

  D 'must return block value' do
    inner = rand()
    outer = T { inner }

    T { inner == outer }
  end
end

D 'F()' do
  F { !true }
  F { false }
  F { nil }

  D 'must return block value' do
    inner = false
    outer = F { inner }

    T { inner == outer }
  end
end

D 'E()' do
  E SyntaxError do
    raise SyntaxError
  end

  D "that doesn't raise fails" do
    E { }
  end

  D "that raises something else fails" do
    E(ArgumentError) { raise SyntaxError }
  end

  D 'allows nested rescue' do
    klass = Class.new(Exception)

    E SyntaxError do
      begin
        raise ArgumentError
      rescue
      end

      raise SyntaxError
    end
  end
end

D 'C()' do
  C :foo do
    throw :foo
  end

  D 'allows nested catch' do
    C :foo do
      catch :bar do
        throw :bar
      end

      throw :foo
    end
  end
end

D 'D()' do
  history = []

  D .<< { history << :before_all  }
  D .<  { history << :before_each }
  D .>  { history << :after_each  }
  D .>> { history << :after_all   }

  D 'first nesting' do
    T { history.select {|x| x == :before_all  }.length == 1 }
    T { history.select {|x| x == :before_each }.length == 1 }
    F { history.select {|x| x == :after_each  }.length == 1 }
    T { history.select {|x| x == :after_all   }.length == 0 }
  end

  D 'second nesting' do
    T { history.select {|x| x == :before_all  }.length == 1 }
    T { history.select {|x| x == :before_each }.length == 2 }
    T { history.select {|x| x == :after_each  }.length == 1 }
    T { history.select {|x| x == :after_all   }.length == 0 }
  end

  D 'third nesting' do
    T { history.select {|x| x == :before_all  }.length == 1 }
    T { history.select {|x| x == :before_each }.length == 3 }
    T { history.select {|x| x == :after_each  }.length == 2 }
    T { history.select {|x| x == :after_all   }.length == 0 }
  end

  D 'fourth nesting' do
    D .<< { history << :nested_before_all  }
    D .<  { history << :nested_before_each }
    D .>  { history << :nested_after_each  }
    D .>> { history << :nested_after_all   }

    nested_before_each = 0

    D .< do
      # outer values remain the same for this nesting
      T { history.select {|x| x == :before_all  }.length == 1 }
      T { history.select {|x| x == :before_each }.length == 4 }
      T { history.select {|x| x == :after_each  }.length == 3 }
      T { history.select {|x| x == :after_all   }.length == 0 }

      nested_before_each += 1
      T { history.select {|x| x == :nested_before_each }.length == nested_before_each }
    end

    D 'first double-nesting' do
      T { history.select {|x| x == :nested_before_all  }.length == 1 }
      T { history.select {|x| x == :nested_before_each }.length == 1 }
      F { history.select {|x| x == :nested_after_each  }.length == 1 }
      T { history.select {|x| x == :nested_after_all   }.length == 0 }
    end

    D 'second double-nesting' do
      T { history.select {|x| x == :nested_before_all  }.length == 1 }
      T { history.select {|x| x == :nested_before_each }.length == 2 }
      T { history.select {|x| x == :nested_after_each  }.length == 1 }
      T { history.select {|x| x == :nested_after_all   }.length == 0 }
    end

    D 'third double-nesting' do
      T { history.select {|x| x == :nested_before_all  }.length == 1 }
      T { history.select {|x| x == :nested_before_each }.length == 3 }
      T { history.select {|x| x == :nested_after_each  }.length == 2 }
      T { history.select {|x| x == :nested_after_all   }.length == 0 }
    end
  end
end

D 'stoping #run' do
  Dfect.stop
  raise 'this must not be reached!'
end
