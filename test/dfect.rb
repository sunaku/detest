#--
# Copyright protects this work.
# See LICENSE file for details.
#++

require 'dfect/auto'

D 'T()' do
  T { true   }
  T { !false }
  T { !nil   }

  T { 0 } # zero is true in Ruby! :)
  T { 1 }

  D 'must return block value' do
    inner = rand()
    outer = T { inner }

    T { outer == inner }
  end
end

D 'T!()' do
  T! { !true }
  T! { false }
  T! { nil   }

  D 'must return block value' do
    inner = nil
    outer = T! { inner }

    T { outer == inner }
  end
end

D 'T?()' do
  T { T? { true  } }
  F { T? { false } }
  F { T? { nil   } }

  D 'must not return block value' do
    inner = rand()
    outer = T? { inner }

    F { outer == inner }
    T { outer == true }
  end
end

D 'F() must be same as T!()' do
  T { D.method(:F) == D.method(:T!) }
end

D 'F!() must be same as T()' do
  T { D.method(:F!) == D.method(:T) }
end

D 'F?()' do
  T { T? { true  } }
  F { T? { false } }
  F { T? { nil   } }

  D 'must not return block value' do
    inner = rand()
    outer = F? { inner }

    F { outer == inner }
    T { outer == false }
  end
end

D 'E()' do
  E(SyntaxError) { raise SyntaxError }

  D 'forbids block to not raise anything' do
    F { E? {} }
  end

  D 'forbids block to raise something unexpected' do
    F { E?(ArgumentError) { raise SyntaxError } }
  end

  D 'defaults to StandardError when no kinds specified' do
    E { raise StandardError }
    E { raise }
  end

  D 'does not default to StandardError when kinds are specified' do
    F { E?(SyntaxError) { raise } }
  end

  D 'allows nested rescue' do
    E SyntaxError do
      begin
        raise LoadError
      rescue LoadError
      end

      raise rescue nil

      raise SyntaxError
    end
  end
end

D 'E!()' do
  E!(SyntaxError) { raise ArgumentError }

  D 'allows block to not raise anything' do
    E!(SyntaxError) {}
  end

  D 'allows block to raise something unexpected' do
    T { not E?(ArgumentError) { raise SyntaxError } }
  end

  D 'defaults to StandardError when no kinds specified' do
    E! { raise LoadError }
  end

  D 'does not default to StandardError when kinds are specified' do
    T { not E?(SyntaxError) { raise } }
  end

  D 'allows nested rescue' do
    E! SyntaxError do
      begin
        raise LoadError
      rescue LoadError
      end

      raise rescue nil

      raise ArgumentError
    end
  end
end

D 'C()' do
  C(:foo) { throw :foo }

  D 'forbids block to not throw anything' do
    F { C?(:bar) {} }
  end

  D 'forbids block to throw something unexpected' do
    F { C?(:bar) { throw :foo } }
  end

  D 'allows nested catch' do
    C :foo do
      catch :bar do
        throw :bar
      end

      throw :foo
    end
  end

  D 'returns the value thrown along with symbol' do
    inner = rand()
    outer = C(:foo) { throw :foo, inner }

    T { outer == inner }
  end
end

D 'C!()' do
  C!(:bar) { throw :foo }

  D 'allows block to not throw anything' do
    C!(:bar) {}
  end

  D 'allows block to throw something unexpected' do
    T { not C?(:bar) { throw :foo } }
  end

  D 'allows nested catch' do
    C! :bar do
      catch :moz do
        throw :moz
      end

      throw :foo
    end
  end

  D 'does not return the value thrown along with symbol' do
    inner = rand()
    outer = C!(:foo) { throw :bar, inner }

    F { outer == inner }
    T { outer == nil   }
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

D 'D.<() must allow inheritance checking when called without a block' do
  F { D < Kernel }
  F { D < Object }
  F { D < Module }
  T { D.class == Module }

  c = Class.new { include D }
  T { c < D }
end

D 'YAML must be able to serialize a class' do
  T { SyntaxError.to_yaml == "--- SyntaxError\n" }
end

D 'insulated root-level describe' do
  @insulated = :insulated
  non_closured = :non_closured
end

closured = :closured

D 'another insulated root-level describe' do
  # without insulation, instance variables
  # from previous root-level describe
  # environments will spill into this one
  F { defined? @insulated }
  F { @insulated == :insulated }

  # however, this insulation must
  # not prevent closure access to
  # surrounding local variables
  T { defined? closured }
  T { closured == :closured }

  # except local variables defined
  # within another insulated environment
  F { defined? non_closured }
  E(NameError) { non_closured }

  @insulated_again = :insulated_again

  D 'non-insulated nested describe' do
    D 'inherits instance variables' do
      T { defined? @insulated_again }
      T { @insulated_again == :insulated_again }
    end

    D 'inherits instance methods' do
      E!(NoMethodError) { instance_level_helper_method }
      T { instance_level_helper_method == :instance_level_helper_method }
    end

    D 'inherits class methods' do
      E!(NoMethodError) { self.class_level_helper_method }
      T { self.class_level_helper_method == :class_level_helper_method }

      E!(NoMethodError) { class_level_helper_method }
      T { class_level_helper_method == self.class_level_helper_method }
    end

    @non_insulated_from_nested = :non_insulated_from_nested
  end

  D 'another non-insulated nested describe' do
    T { defined? @non_insulated_from_nested }
    T { @non_insulated_from_nested == :non_insulated_from_nested }
  end

  def instance_level_helper_method
    :instance_level_helper_method
  end

  def self.class_level_helper_method
    :class_level_helper_method
  end
end

D 'yet another insulated root-level describe' do
  F { defined? @insulated_again }
  F { @insulated_again == :insulated_again }

  F { defined? @non_insulated_from_nested }
  F { @non_insulated_from_nested == :non_insulated_from_nested }
end

S :knowledge do
  @sharing_is_fun = true
end

S :money do
  @sharing_is_fun = false
end

D 'share knowledge' do
  F { defined? @sharing_is_fun }
  S :knowledge
  T { defined? @sharing_is_fun }
  T { @sharing_is_fun }
end

D 'share money' do
  F { defined? @sharing_is_fun }
  S :money
  T { defined? @sharing_is_fun }
  F { @sharing_is_fun }
end

D 'stoping #run' do
  Dfect.stop
  raise 'this must not be reached!'
end
