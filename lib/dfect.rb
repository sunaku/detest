#--
# Copyright protects this work.
# See LICENSE file for details.
#++

require 'yaml'
#
# YAML raises this error when we try to serialize a class:
#
#   TypeError: can't dump anonymous class Class
#
# Work around this by representing a class by its name.
#
class Class #:nodoc: all
  alias __to_yaml__ to_yaml
  undef to_yaml

  def to_yaml opts = {}
    begin
      __to_yaml__
    rescue TypeError => e
      warn e
      self.name.to_yaml opts
    end
  end
end

# load interactive debugger
begin

  begin
    require 'rubygems'
  rescue LoadError
  end

  require 'ruby-debug'

rescue LoadError
  require 'irb'
end

module Dfect
  class << self
    ##
    # Hash of test results, assembled by #run.
    #
    # [:execution]
    #   Hierarchical trace of all tests executed, where each test is
    #   represented by its description, is mapped to an Array of
    #   nested tests, and may contain zero or more assertion failures.
    #
    #   Assertion failures are represented as a Hash:
    #
    #   ["fail"]
    #     Description of the assertion failure.
    #
    #   ["code"]
    #     Source code surrounding the point of failure.
    #
    #   ["vars"]
    #     Local variables visible at the point of failure.
    #
    #   ["call"]
    #     Stack trace leading to the point of failure.
    #
    # [:statistics]
    #   Hash of counts of major events in test execution:
    #
    #   [:passed_assertions]
    #     Number of assertions that held true.
    #
    #   [:failed_assertions]
    #     Number of assertions that did not hold true.
    #
    #   [:uncaught_exceptions]
    #     Number of exceptions that were not rescued.
    #
    attr_reader :report

    ##
    # Hash of choices that affect how Dfect operates.
    #
    # [:debug]
    #   Launch an interactive debugger
    #   during assertion failures so
    #   the user can investigate them.
    #
    #   The default value is true.
    #
    # [:quiet]
    #   Do not print the report
    #   after executing all tests.
    #
    #   The default value is false.
    #
    attr_accessor :options

    ##
    # Defines a new test, composed of the given
    # description and the given block to execute.
    #
    # A test may contain nested tests.
    #
    # ==== Parameters
    #
    # [description]
    #   A short summary of the test being defined.
    #
    # ==== Examples
    #
    #   D "a new array" do
    #     D .< { @array = [] }
    #
    #     D "must be empty" do
    #       T { @array.empty? }
    #     end
    #
    #     D "when populated" do
    #       D .< { @array.push 55 }
    #
    #       D "must not be empty" do
    #         F { @array.empty? }
    #       end
    #     end
    #   end
    #
    def D description = caller.first, &block
      raise ArgumentError, 'block must be given' unless block
      @curr_suite.tests << Suite::Test.new(description.to_s, block)
    end

    ##
    # :call-seq: <(&block)
    #
    # Registers the given block to be executed
    # before each nested test inside this test.
    #
    # ==== Examples
    #
    #   D .< { puts "before each nested test" }
    #
    #   D .< do
    #     puts "before each nested test"
    #   end
    #
    def <(*args, &block)
      if args.empty?
        raise ArgumentError, 'block must be given' unless block
        @curr_suite.before_each << block
      else
        # the < method is being used as a check for inheritance
        super
      end
    end

    ##
    # Registers the given block to be executed
    # after each nested test inside this test.
    #
    # ==== Examples
    #
    #   D .> { puts "after each nested test" }
    #
    #   D .> do
    #     puts "after each nested test"
    #   end
    #
    def > &block
      raise ArgumentError, 'block must be given' unless block
      @curr_suite.after_each << block
    end

    ##
    # Registers the given block to be executed
    # before all nested tests inside this test.
    #
    # ==== Examples
    #
    #   D .<< { puts "before all nested tests" }
    #
    #   D .<< do
    #     puts "before all nested tests"
    #   end
    #
    def << &block
      raise ArgumentError, 'block must be given' unless block
      @curr_suite.before_all << block
    end

    ##
    # Registers the given block to be executed
    # after all nested tests inside this test.
    #
    # ==== Examples
    #
    #   D .>> { puts "after all nested tests" }
    #
    #   D .>> do
    #     puts "after all nested tests"
    #   end
    #
    def >> &block
      raise ArgumentError, 'block must be given' unless block
      @curr_suite.after_all << block
    end

    ##
    # Asserts that the result of the given block is
    # neither nil nor false and returns that result.
    #
    # ==== Parameters
    #
    # [message]
    #   Optional message to show in the
    #   report if this assertion fails.
    #
    # ==== Examples
    #
    #   # no message specified:
    #
    #   T { true }  # passes
    #   T { false } # fails
    #   T { nil }   # fails
    #
    #   # message specified:
    #
    #   T( "computers do not doublethink" ) { 2 + 2 != 5 } # passes
    #
    def T message = nil, &block
      assert_yield :assert, message, &block
    end

    ##
    # Asserts that the result of the given block is
    # either nil or false and returns that result.
    #
    # ==== Parameters
    #
    # [message]
    #   Optional message to show in the
    #   report if this assertion fails.
    #
    # ==== Examples
    #
    #   # no message specified:
    #
    #   T! { true }  # fails
    #   T! { false } # passes
    #   T! { nil }   # passes
    #
    #   # message specified:
    #
    #   T!( "computers do not doublethink" ) { 2 + 2 == 5 } # passes
    #
    def T! message = nil, &block
      assert_yield :negate, message, &block
    end

    ##
    # Returns true if the result of the given block is
    # neither nil nor false.  Otherwise, returns false.
    #
    # ==== Parameters
    #
    # [message]
    #   This parameter is optional and completely ignored.
    #
    # ==== Examples
    #
    #   # no message specified:
    #
    #   T? { true }  # => true
    #   T? { false } # => false
    #   T? { nil }   # => false
    #
    #   # message specified:
    #
    #   T?( "computers do not doublethink" ) { 2 + 2 != 5 } # => true
    #
    def T? message = nil, &block
      assert_yield :sample, message, &block
    end

    alias F T!

    alias F! T

    ##
    # Returns true if the result of the given block is
    # either nil or false.  Otherwise, returns false.
    #
    # ==== Parameters
    #
    # [message]
    #   This parameter is optional and completely ignored.
    #
    # ==== Examples
    #
    #   # no message specified:
    #
    #   F? { true }  # => false
    #   F? { false } # => true
    #   F? { nil }   # => true
    #
    #   # message specified:
    #
    #   F?( "computers do not doublethink" ) { 2 + 2 == 5 } # => true
    #
    def F? message = nil, &block
      not T? message, &block
    end

    ##
    # Asserts that one of the given
    # kinds of exceptions is raised
    # when the given block is executed.
    #
    # If the block raises an exception,
    # then that exception is returned.
    #
    # Otherwise, nil is returned.
    #
    # ==== Parameters
    #
    # [message]
    #   Optional message to show in the
    #   report if this assertion fails.
    #
    # [kinds]
    #   Exception classes that must be raised by the given block.
    #
    #   If none are given, then StandardError is assumed (similar to how a
    #   plain 'rescue' statement without any arguments catches StandardError).
    #
    # ==== Examples
    #
    #   # no exceptions specified:
    #
    #   E { }       # fails
    #   E { raise } # passes
    #
    #   # single exception specified:
    #
    #   E( ArgumentError ) { raise ArgumentError }
    #   E( "argument must be invalid", ArgumentError ) { raise ArgumentError }
    #
    #   # multiple exceptions specified:
    #
    #   E( SyntaxError, NameError ) { eval "..." }
    #   E( "string must compile", SyntaxError, NameError ) { eval "..." }
    #
    def E message = nil, *kinds, &block
      assert_raise :assert, message, *kinds, &block
    end

    ##
    # Asserts that one of the given kinds of exceptions
    # is not raised when the given block is executed.
    #
    # If the block raises an exception,
    # then that exception is returned.
    #
    # Otherwise, nil is returned.
    #
    # ==== Parameters
    #
    # [message]
    #   Optional message to show in the
    #   report if this assertion fails.
    #
    # [kinds]
    #   Exception classes that must not be raised by the given block.
    #
    #   If none are given, then StandardError is assumed (similar to how a
    #   plain 'rescue' statement without any arguments catches StandardError).
    #
    # ==== Examples
    #
    #   # no exceptions specified:
    #
    #   E! { }       # passes
    #   E! { raise } # fails
    #
    #   # single exception specified:
    #
    #   E!( ArgumentError ) { raise ArgumentError } # fails
    #   E!( "argument must be invalid", ArgumentError ) { raise ArgumentError }
    #
    #   # multiple exceptions specified:
    #
    #   E!( SyntaxError, NameError ) { eval "..." }
    #   E!( "string must compile", SyntaxError, NameError ) { eval "..." }
    #
    def E! message = nil, *kinds, &block
      assert_raise :negate, message, *kinds, &block
    end

    ##
    # Returns true if one of the given kinds of
    # exceptions is raised when the given block
    # is executed.  Otherwise, returns false.
    #
    # ==== Parameters
    #
    # [message]
    #   This parameter is optional and completely ignored.
    #
    # [kinds]
    #   Exception classes that must be raised by the given block.
    #
    #   If none are given, then StandardError is assumed (similar to how a
    #   plain 'rescue' statement without any arguments catches StandardError).
    #
    # ==== Examples
    #
    #   # no exceptions specified:
    #
    #   E? { }       # => false
    #   E? { raise } # => true
    #
    #   # single exception specified:
    #
    #   E?( ArgumentError ) { raise ArgumentError } # => true
    #
    #   # multiple exceptions specified:
    #
    #   E?( SyntaxError, NameError ) { eval "..." } # => true
    #
    def E? message = nil, *kinds, &block
      assert_raise :sample, message, *kinds, &block
    end

    ##
    # Asserts that the given symbol is thrown
    # when the given block is executed.
    #
    # If a value is thrown along
    # with the expected symbol,
    # then that value is returned.
    #
    # Otherwise, nil is returned.
    #
    # ==== Parameters
    #
    # [message]
    #   Optional message to show in the
    #   report if this assertion fails.
    #
    # [symbol]
    #   Symbol that must be thrown by the given block.
    #
    # ==== Examples
    #
    #   # no message specified:
    #
    #   C(:foo) { throw :foo, 123 } # passes, => 123
    #   C(:foo) { throw :bar, 456 } # fails,  => 456
    #   C(:foo) { }                 # fails,  => nil
    #
    #   # message specified:
    #
    #   C( ":foo must be thrown", :foo ) { throw :bar, 789 } # fails, => nil
    #
    def C message = nil, symbol = nil, &block
      assert_catch :assert, message, symbol, &block
    end

    ##
    # Asserts that the given symbol is not
    # thrown when the given block is executed.
    #
    # Returns nil, always.
    #
    # ==== Parameters
    #
    # [message]
    #   Optional message to show in the
    #   report if this assertion fails.
    #
    # [symbol]
    #   Symbol that must not be thrown by the given block.
    #
    # ==== Examples
    #
    #   # no message specified:
    #
    #   C!(:foo) { throw :foo, 123 } # fails,  => nil
    #   C!(:foo) { throw :bar, 456 } # passes, => nil
    #   C!(:foo) { }                 # passes, => nil
    #
    #   # message specified:
    #
    #   C!( ":foo must be thrown", :foo ) { throw :bar, 789 } # passes, => nil
    #
    def C! message = nil, symbol = nil, &block
      assert_catch :negate, message, symbol, &block
    end

    ##
    # Returns true if the given symbol is thrown when the
    # given block is executed.  Otherwise, returns false.
    #
    # ==== Parameters
    #
    # [message]
    #   This parameter is optional and completely ignored.
    #
    # [symbol]
    #   Symbol that must be thrown by the given block.
    #
    # ==== Examples
    #
    #   # no message specified:
    #
    #   C?(:foo) { throw :foo, 123 } # => true
    #   C?(:foo) { throw :bar, 456 } # => false
    #   C?(:foo) { }                 # => false
    #
    #   # message specified:
    #
    #   C?( ":foo must be thrown", :foo ) { throw :bar, 789 } # => false
    #
    def C? message = nil, symbol = nil, &block
      assert_catch :sample, message, symbol, &block
    end

    ##
    # Executes all tests defined thus far and stores the results in #report.
    #
    # ==== Parameters
    #
    # [continue]
    #   If true, results from previous executions will not be cleared.
    #
    def run continue = true
      # clear previous results
      unless continue
        @exec_stats.clear
        @exec_trace.clear
        @test_stack.clear
      end

      # make new results
      catch(:stop_dfect_execution) { execute }

      # print new results
      puts @report.to_yaml unless @options[:quiet]
    end

    ##
    # Stops the execution of the #run method or raises an
    # exception if that method is not currently executing.
    #
    def stop
      throw :stop_dfect_execution
    end

    private

    def assert_yield mode, message = nil, &block
      raise ArgumentError, 'block must be given' unless block

      message ||=
        case mode
        when :assert then 'block must yield true (!nil && !false)'
        when :negate then 'block must yield false (nil || false)'
        end

      passed = lambda do
        @exec_stats[:passed_assertions] += 1
      end

      failed = lambda do
        @exec_stats[:failed_assertions] += 1
        debug block, message
      end

      result = call(block)

      case mode
      when :sample then return result ? true : false
      when :assert then result ? passed.call : failed.call
      when :negate then result ? failed.call : passed.call
      end

      result
    end

    def assert_raise mode, message = nil, *kinds, &block
      raise ArgumentError, 'block must be given' unless block

      if message.is_a? Class
        kinds.unshift message
        message = nil
      end

      kinds << StandardError if kinds.empty?

      message ||=
        case mode
        when :assert then "block must raise #{kinds.join ' or '}"
        when :negate then "block must not raise #{kinds.join ' or '}"
        end

      passed = lambda do
        @exec_stats[:passed_assertions] += 1
      end

      failed = lambda do |exception|
        @exec_stats[:failed_assertions] += 1

        if exception
          # debug the uncaught exception...
          debug_uncaught_exception block, exception

          # ...in addition to debugging this assertion
          debug block, [message, {'block raised' => exception}]

        else
          debug block, message
        end
      end

      begin
        block.call

      rescue Exception => exception
        expected = kinds.any? {|k| exception.kind_of? k }

        case mode
        when :sample then return expected
        when :assert then expected ? passed.call : failed.call(exception)
        when :negate then expected ? failed.call(exception) : passed.call
        end

      else # nothing was raised
        case mode
        when :sample then return false
        when :assert then failed.call nil
        when :negate then passed.call
        end
      end

      exception
    end

    def assert_catch mode, message = nil, symbol = nil, &block
      raise ArgumentError, 'block must be given' unless block

      if message.is_a? Symbol and not symbol
        symbol  = message
        message = nil
      end

      raise ArgumentError, 'symbol must be given' unless symbol

      symbol = symbol.to_sym
      message ||= "block must throw #{symbol.inspect}"

      passed = lambda do
        @exec_stats[:passed_assertions] += 1
      end

      failed = lambda do
        @exec_stats[:failed_assertions] += 1
        debug block, message
      end

      # if nothing was thrown, the result of catch()
      # is simply the result of executing the block
      result = catch(symbol) do
        begin
          block.call

        rescue Exception => e
          debug_uncaught_exception block, e unless
            # ignore error about the wrong symbol being thrown
            #
            # NOTE: Ruby 1.8 formats the thrown value in `quotes'
            #       whereas Ruby 1.9 formats it like a :symbol
            #
            e.message =~ /\Auncaught throw (`.*?'|:.*)\z/
        end

        self # unlikely that block will throw *this* object
      end

      caught = result != self
      result = nil unless caught

      case mode
      when :sample then return caught
      when :assert then caught ? passed.call : failed.call
      when :negate then caught ? failed.call : passed.call
      end

      result
    end

    ##
    # Executes the current test suite recursively.
    #
    def execute
      suite = @curr_suite
      trace = @exec_trace

      suite.before_all.each {|b| call b }

      suite.tests.each do |test|
        suite.before_each.each {|b| call b }

        @test_stack.push test

        begin
          # create nested suite
          @curr_suite = Suite.new
          @exec_trace = []

          # populate nested suite
          call test.block

          # execute nested suite
          execute

        ensure
          # restore outer values
          @curr_suite = suite

          trace << build_trace(@exec_trace)
          @exec_trace = trace
        end

        @test_stack.pop

        suite.after_each.each {|b| call b }
      end

      suite.after_all.each {|b| call b }
    end

    ##
    # Invokes the given block and debugs any
    # exceptions that may arise as a result.
    #
    def call block
      begin
        block.call
      rescue Exception => e
        debug_uncaught_exception block, e
      end
    end

    INTERNALS = File.dirname(__FILE__) #:nodoc:

    ##
    # Adds debugging information to the report.
    #
    # ==== Parameters
    #
    # [context]
    #   Binding of code being debugged.  This
    #   can be either a Binding or Proc object.
    #
    # [message]
    #   Message describing the failure
    #   in the code being debugged.
    #
    # [backtrace]
    #   Stack trace corresponding to point of
    #   failure in the code being debugged.
    #
    def debug context, message = nil, backtrace = caller
      # allow a Proc to be passed instead of a binding
      if context.respond_to? :binding
        context = context.binding
      end

      # omit internals from failure details
      backtrace = backtrace.reject {|s| s.include? INTERNALS }

      # record failure details in the report
      #
      # NOTE: using string keys here instead
      #       of symbols because they make
      #       the YAML output easier to read
      #
      details = {
        # user message
        'fail' => message,

        # code snippet
        'code' => (
          if frame = backtrace.first
            file, line = frame.scan(/(.+?):(\d+(?=:|\z))/).first

            if source = @file_cache[file]
              line = line.to_i

              radius = 5 # number of surrounding lines to show
              region = [line - radius, 1].max ..
                       [line + radius, source.length].min

              # ensure proper alignment by zero-padding line numbers
              format = "%2s %0#{region.last.to_s.length}d %s"

              pretty = region.map do |n|
                format % [('=>' if n == line), n, source[n-1].chomp]
              end

              pretty.unshift "[#{region.inspect}] in #{file}"

              # to_yaml will render the paragraph without escaping newlines
              # ONLY IF the first and last character are non-whitespace
              pretty.join("\n").strip
            end
          end
        ),

        # variable values
        'vars' => (
          names = eval('::Kernel.local_variables', context, __FILE__, __LINE__)

          pairs = names.inject([]) do |pair, name|
            variable = name.to_s
            value    = eval(variable, context, __FILE__, __LINE__)

            pair.push variable, value
          end

          Hash[*pairs]
        ),

        # stack trace
        'call' => backtrace,
      }

      @exec_trace << details

      # allow user to investigate the failure
      if @options[:debug]
        # show the failure to the user
        puts build_trace(details).to_yaml

        # start the investigation
        if Kernel.respond_to? :debugger
          eval '::Kernel.debugger', context, __FILE__, __LINE__
        else
          IRB.setup nil

          env = IRB::WorkSpace.new(context)
          irb = IRB::Irb.new(env)
          IRB.conf[:MAIN_CONTEXT] = irb.context

          catch :IRB_EXIT do
            irb.eval_input
          end
        end
      end

      nil
    end

    ##
    # Debugs the given uncaught exception inside the given context.
    #
    def debug_uncaught_exception context, exception
      @exec_stats[:uncaught_exceptions] += 1
      debug context, exception, exception.backtrace
    end

    ##
    # Returns a report that associates the given
    # failure details with the currently running test.
    #
    def build_trace details
      if @test_stack.empty?
        details
      else
        { @test_stack.last.desc => details }
      end
    end

    #:stopdoc:

    class Suite
      attr_reader :tests, :before_each, :after_each, :before_all, :after_all

      def initialize
        @tests       = []
        @before_each = []
        @after_each  = []
        @before_all  = []
        @after_all   = []
      end

      Test = Struct.new :desc, :block
    end

    #:startdoc:
  end

  @options    = {:debug => true, :quiet => false}

  @exec_stats = Hash.new {|h,k| h[k] = 0 }
  @exec_trace = []
  @report     = {:execution => @exec_trace, :statistics => @exec_stats}.freeze

  @curr_suite = class << self; Suite.new; end

  @test_stack = []
  @file_cache = Hash.new {|h,k| h[k] = File.readlines(k) rescue nil }

  ##
  # Allows before and after hooks to be specified via
  # the D() method syntax when this module is mixed-in:
  #
  #   D .<  { puts "before each nested test" }
  #   D .>  { puts "after  each nested test" }
  #   D .<< { puts "before all nested tests" }
  #   D .>> { puts "after  all nested tests" }
  #
  D = self

  # provide mixin-able assertion methods
  methods(false).grep(/^[[:upper:]][[:punct:]]?$/).each do |name|
    #
    # XXX: using eval() on a string because Ruby 1.8's
    #      define_method() cannot take a block parameter
    #
    eval "def #{name}(*a, &b) ::#{self}.#{name}(*a, &b) end", binding, __FILE__, __LINE__
  end
end
