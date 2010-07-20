require 'dfect/inochi'

require 'yaml'
#
# YAML raises this error when we try to serialize a class:
#
#   TypeError: can't dump anonymous class Class
#
# Work around this by representing a class by its name.
#
class Class # @private
  alias __to_yaml__ to_yaml
  undef to_yaml

  def to_yaml opts = {}
    begin
      __to_yaml__
    rescue TypeError => e
      self.name.to_yaml opts
    end
  end
end

module Dfect
  class << self
    ##
    # Hash of test results, assembled by {Dfect.run}.
    #
    # [:trace]
    #   Hierarchical trace of all tests executed, where each test is
    #   represented by its description, is mapped to an Array of
    #   nested tests, and may contain zero or more assertion failures.
    #
    #   Assertion failures are represented as a Hash:
    #
    #   [:fail]
    #     Description of the assertion failure.
    #
    #   [:code]
    #     Source code surrounding the point of failure.
    #
    #   [:vars]
    #     Local variables visible at the point of failure.
    #
    #   [:call]
    #     Stack trace leading to the point of failure.
    #
    # [:stats]
    #   Hash of counts of major events in test execution:
    #
    #   [:time]
    #     Number of seconds elapsed for test execution.
    #
    #   [:pass]
    #     Number of assertions that held true.
    #
    #   [:fail]
    #     Number of assertions that did not hold true.
    #
    #   [:error]
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
    #   The default value is $DEBUG.
    #
    # [:quiet]
    #   Do not print the report
    #   after executing all tests.
    #
    #   The default value is false.
    #
    attr_accessor :options

    ##
    # Defines a new test composed of the given
    # description and the given block to execute.
    #
    # This test may contain nested tests.
    #
    # Tests at the outer-most level are automatically
    # insulated from the top-level Ruby environment.
    #
    # @param [Object, Array<Object>] description
    #
    #   A brief title or a series of objects
    #   that describe the test being defined.
    #
    # @example
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
    def D *description, &block
      create_test @tests.empty?, *description, &block
    end

    ##
    # Defines a new test that is explicitly insulated from the tests
    # that contain it and also from the top-level Ruby environment.
    #
    # This test may contain nested tests.
    #
    # @param description (see Dfect.D)
    #
    # @example
    #
    #   D "a root-level test" do
    #     @outside = 1
    #     T { defined? @outside }
    #     T { @outside == 1 }
    #
    #     D "an inner, non-insulated test" do
    #       T { defined? @outside }
    #       T { @outside == 1 }
    #     end
    #
    #     D! "an inner, insulated test" do
    #       F { defined? @outside }
    #       F { @outside == 1 }
    #
    #       @inside = 2
    #       T { defined? @inside }
    #       T { @inside == 2 }
    #     end
    #
    #     F { defined? @inside }
    #     F { @inside == 2 }
    #   end
    #
    def D! *description, &block
      create_test true, *description, &block
    end

    ##
    # @overload def <(&block)
    #
    # Registers the given block to be executed
    # before each nested test inside this test.
    #
    # @example
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
        @suite.before_each << block
      else
        # the < method is being used as a check for inheritance
        super
      end
    end

    ##
    # Registers the given block to be executed
    # after each nested test inside this test.
    #
    # @example
    #
    #   D .> { puts "after each nested test" }
    #
    #   D .> do
    #     puts "after each nested test"
    #   end
    #
    def > &block
      raise ArgumentError, 'block must be given' unless block
      @suite.after_each << block
    end

    ##
    # Registers the given block to be executed
    # before all nested tests inside this test.
    #
    # @example
    #
    #   D .<< { puts "before all nested tests" }
    #
    #   D .<< do
    #     puts "before all nested tests"
    #   end
    #
    def << &block
      raise ArgumentError, 'block must be given' unless block
      @suite.before_all << block
    end

    ##
    # Registers the given block to be executed
    # after all nested tests inside this test.
    #
    # @example
    #
    #   D .>> { puts "after all nested tests" }
    #
    #   D .>> do
    #     puts "after all nested tests"
    #   end
    #
    def >> &block
      raise ArgumentError, 'block must be given' unless block
      @suite.after_all << block
    end

    ##
    # Asserts that the given condition or the
    # result of the given block is neither
    # nil nor false and returns that result.
    #
    # @param condition
    #
    #   The condition to be asserted.  A block
    #   may be given in place of this parameter.
    #
    # @param message
    #
    #   Optional message to show in the
    #   report if this assertion fails.
    #
    # @example no message given
    #
    #   T { true }  # passes
    #   T { false } # fails
    #   T { nil }   # fails
    #
    # @example message is given
    #
    #   T("computers do not doublethink") { 2 + 2 != 5 } # passes
    #
    def T condition = nil, message = nil, &block
      assert_yield :assert, condition, message, &block
    end

    ##
    # Asserts that the given condition or the
    # result of the given block is either nil
    # or false and returns that result.
    #
    # @param condition (see Dfect.T)
    #
    # @param message (see Dfect.T)
    #
    # @example no message given
    #
    #   T! { true }  # fails
    #   T! { false } # passes
    #   T! { nil }   # passes
    #
    # @example message is given
    #
    #   T!("computers do not doublethink") { 2 + 2 == 5 } # passes
    #
    def T! condition = nil, message = nil, &block
      assert_yield :negate, condition, message, &block
    end

    ##
    # Returns true if the given condition or
    # the result of the given block is neither
    # nil nor false.  Otherwise, returns false.
    #
    # @param condition (see Dfect.T)
    #
    # @param message
    #
    #   This parameter is optional and completely ignored.
    #
    # @example no message given
    #
    #   T? { true }  # => true
    #   T? { false } # => false
    #   T? { nil }   # => false
    #
    # @example message is given
    #
    #   T?("computers do not doublethink") { 2 + 2 != 5 } # => true
    #
    def T? condition = nil, message = nil, &block
      assert_yield :sample, condition, message, &block
    end

    alias F T!

    alias F! T

    ##
    # Returns true if the result of the given block is
    # either nil or false.  Otherwise, returns false.
    #
    # @param message (see Dfect.T?)
    #
    # @example no message given
    #
    #   F? { true }  # => false
    #   F? { false } # => true
    #   F? { nil }   # => true
    #
    # @example message is given
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
    # @return
    #
    #   If the block raises an exception,
    #   then that exception is returned.
    #
    #   Otherwise, nil is returned.
    #
    # @param [...] kinds_then_message
    #
    #   Exception classes that must be raised by the given block, optionally
    #   followed by a message to show in the report if this assertion fails.
    #
    #   If no exception classes are given, then
    #   StandardError is assumed (similar to
    #   how a plain 'rescue' statement without
    #   any arguments catches StandardError).
    #
    # @example no exceptions given
    #
    #   E { }       # fails
    #   E { raise } # passes
    #
    # @example single exception given
    #
    #   E(ArgumentError) { raise ArgumentError }
    #   E(ArgumentError, "argument must be invalid") { raise ArgumentError }
    #
    # @example multiple exceptions given
    #
    #   E(SyntaxError, NameError) { eval "..." }
    #   E(SyntaxError, NameError, "string must compile") { eval "..." }
    #
    def E *kinds_then_message, &block
      assert_raise :assert, *kinds_then_message, &block
    end

    ##
    # Asserts that one of the given kinds of exceptions
    # is not raised when the given block is executed.
    #
    # @return (see Dfect.E)
    #
    # @param kinds_then_message (see Dfect.E)
    #
    # @example no exceptions given
    #
    #   E! { }       # passes
    #   E! { raise } # fails
    #
    # @example single exception given
    #
    #   E!(ArgumentError) { raise ArgumentError } # fails
    #   E!(ArgumentError, "argument must be invalid") { raise ArgumentError }
    #
    # @example multiple exceptions given
    #
    #   E!(SyntaxError, NameError) { eval "..." }
    #   E!(SyntaxError, NameError, "string must compile") { eval "..." }
    #
    def E! *kinds_then_message, &block
      assert_raise :negate, *kinds_then_message, &block
    end

    ##
    # Returns true if one of the given kinds of
    # exceptions is raised when the given block
    # is executed.  Otherwise, returns false.
    #
    # @param [...] kinds_then_message
    #
    #   Exception classes that must be raised by
    #   the given block, optionally followed by
    #   a message that is completely ignored.
    #
    #   If no exception classes are given, then
    #   StandardError is assumed (similar to
    #   how a plain 'rescue' statement without
    #   any arguments catches StandardError).
    #
    # @example no exceptions given
    #
    #   E? { }       # => false
    #   E? { raise } # => true
    #
    # @example single exception given
    #
    #   E?(ArgumentError) { raise ArgumentError } # => true
    #
    # @example multiple exceptions given
    #
    #   E?(SyntaxError, NameError) { eval "..." } # => true
    #   E!(SyntaxError, NameError, "string must compile") { eval "..." }
    #
    def E? *kinds_then_message, &block
      assert_raise :sample, *kinds_then_message, &block
    end

    ##
    # Asserts that the given symbol is thrown
    # when the given block is executed.
    #
    # @return
    #
    #   If a value is thrown along
    #   with the expected symbol,
    #   then that value is returned.
    #
    #   Otherwise, nil is returned.
    #
    # @param [Symbol] symbol
    #
    #   Symbol that must be thrown by the given block.
    #
    # @param message (see Dfect.T)
    #
    # @example no message given
    #
    #   C(:foo) { throw :foo, 123 } # passes, => 123
    #   C(:foo) { throw :bar, 456 } # fails,  => 456
    #   C(:foo) { }                 # fails,  => nil
    #
    # @example message is given
    #
    #   C(:foo, ":foo must be thrown") { throw :bar, 789 } # fails, => nil
    #
    def C symbol, message = nil, &block
      assert_catch :assert, symbol, message, &block
    end

    ##
    # Asserts that the given symbol is not
    # thrown when the given block is executed.
    #
    # @return nil, always.
    #
    # @param [Symbol] symbol
    #
    #   Symbol that must not be thrown by the given block.
    #
    # @param message (see Dfect.T)
    #
    # @example no message given
    #
    #   C!(:foo) { throw :foo, 123 } # fails,  => nil
    #   C!(:foo) { throw :bar, 456 } # passes, => nil
    #   C!(:foo) { }                 # passes, => nil
    #
    # @example message is given
    #
    #   C!(:foo, ":foo must be thrown") { throw :bar, 789 } # passes, => nil
    #
    def C! symbol, message = nil, &block
      assert_catch :negate, symbol, message, &block
    end

    ##
    # Returns true if the given symbol is thrown when the
    # given block is executed.  Otherwise, returns false.
    #
    # @param symbol (see Dfect.C)
    #
    # @param message (see Dfect.T?)
    #
    # @example no message given
    #
    #   C?(:foo) { throw :foo, 123 } # => true
    #   C?(:foo) { throw :bar, 456 } # => false
    #   C?(:foo) { }                 # => false
    #
    # @example message is given
    #
    #   C?(:foo, ":foo must be thrown") { throw :bar, 789 } # => false
    #
    def C? symbol, message = nil, &block
      assert_catch :sample, symbol, message, &block
    end

    ##
    # Adds the given messages to the report inside
    # the section of the currently running test.
    #
    # You can think of "L" as "to log something".
    #
    # @param messages
    #
    #   Objects to be added to the report.
    #
    # @example single message given
    #
    #   L "establishing connection..."
    #
    # @example multiple messages given
    #
    #   L "beginning calculation...", Math::PI, [1, 2, 3, ['a', 'b', 'c']]
    #
    def L *messages
      @trace.concat messages
    end

    ##
    # Mechanism for sharing code between tests.
    #
    # If a block is given, it is shared under
    # the given identifier.  Otherwise, the
    # code block that was previously shared
    # under the given identifier is injected
    # into the closest insulated Dfect test
    # that contains the call to this method.
    #
    # @param [Symbol, Object] identifier
    #
    #   An object that identifies shared code.  This must be common
    #   knowledge to all parties that want to partake in the sharing.
    #
    # @example
    #
    #   S :knowledge do
    #     #...
    #   end
    #
    #   D "some test" do
    #     S :knowledge
    #   end
    #
    #   D "another test" do
    #     S :knowledge
    #   end
    #
    def S identifier, &block
      if block_given?
        if already_shared = @share[identifier]
          raise ArgumentError, "A code block #{already_shared.inspect} has already been shared under the identifier #{identifier.inspect}."
        end

        @share[identifier] = block

      elsif block = @share[identifier]
        if @tests.empty?
          raise "Cannot inject code block #{block.inspect} shared under identifier #{identifier.inspect} outside of a Dfect test."
        else
          # find the closest insulated parent test; this should always
          # succeed because root-level tests are insulated by default
          test = @tests.reverse.find {|t| t.sandbox }
          test.sandbox.instance_eval(&block)
        end

      else
        raise ArgumentError, "No code block is shared under identifier #{identifier.inspect}."
      end
    end

    ##
    # Shares the given code block under the given
    # identifier and then immediately injects that
    # code block into the closest insulated Dfect
    # test that contains the call to this method.
    #
    # @param identifier (see Dfect.S)
    #
    # @example
    #
    #   D "some test" do
    #     S! :knowledge do
    #       #...
    #     end
    #   end
    #
    #   D "another test" do
    #     S :knowledge
    #   end
    #
    def S! identifier, &block
      raise 'block must be given' unless block_given?
      S identifier, &block
      S identifier
    end

    ##
    # Checks whether any code has been shared under the given identifier.
    #
    def S? identifier
      @share.key? identifier
    end

    ##
    # Executes all tests defined thus far and
    # stores the results in {Dfect.report}.
    #
    # @param [Boolean] continue
    #
    #   If true, results from previous executions will not be cleared.
    #
    def run continue = true
      # clear previous results
      unless continue
        @stats.clear
        @trace.clear
        @tests.clear
      end

      # make new results
      start = Time.now
      catch(:stop_dfect_execution) do
        @@caller_bindings.track do
          execute
        end
      end
      finish = Time.now
      @stats[:time] = finish - start

      # print new results
      unless @stats.key? :fail or @stats.key? :error
        #
        # show execution trace only if all tests passed.
        # otherwise, we will be repeating already printed
        # failure details and obstructing the developer!
        #
        display @trace
      end

      display @stats
    end

    ##
    # Stops the execution of the {Dfect.run} method or raises
    # an exception if that method is not currently executing.
    #
    def stop
      throw :stop_dfect_execution
    end

    ##
    # Returns the details of the failure that
    # is currently being debugged by the user.
    #
    def info
      @trace.last
    end

    private

    def create_test insulate, *description, &block
      raise ArgumentError, 'block must be given' unless block

      description = description.join(' ')
      sandbox = Object.new if insulate

      @suite.tests << Suite::Test.new(description, block, sandbox)
    end

    def assert_yield mode, condition = nil, message = nil, &block
      # first parameter is actually the message when block is given
      message = condition if block

      message ||= (
        prefix = block ? 'block must yield' : 'condition must be'
        case mode
        when :assert then "#{prefix} true (!nil && !false)"
        when :negate then "#{prefix} false (nil || false)"
        end
      )

      passed = lambda do
        @stats[:pass] += 1
      end

      failed = lambda do
        @stats[:fail] += 1
        debug block, message
      end

      result = block ? call(block) : condition

      case mode
      when :sample then return result ? true : false
      when :assert then result ? passed.call : failed.call
      when :negate then result ? failed.call : passed.call
      end

      result
    end

    def assert_raise mode, *kinds_then_message, &block
      raise ArgumentError, 'block must be given' unless block

      message = kinds_then_message.pop
      kinds = kinds_then_message

      if message.kind_of? Class
        kinds << message
        message = nil
      end

      kinds << StandardError if kinds.empty?

      message ||=
        case mode
        when :assert then "block must raise #{kinds.join ' or '}"
        when :negate then "block must not raise #{kinds.join ' or '}"
        end

      passed = lambda do
        @stats[:pass] += 1
      end

      failed = lambda do |exception|
        @stats[:fail] += 1

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

    def assert_catch mode, symbol, message = nil, &block
      raise ArgumentError, 'block must be given' unless block

      symbol = symbol.to_sym
      message ||= "block must throw #{symbol.inspect}"

      passed = lambda do
        @stats[:pass] += 1
      end

      failed = lambda do
        @stats[:fail] += 1
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
    # Prints the given object in YAML format.
    #
    def display object, force = false
      if force or not @options[:quiet]
        # stringify symbols in YAML output for better readability
        puts object.to_yaml.gsub(/^([[:blank:]]*(- )?):(?=@?\w+: )/, '\1')
      end
    end

    ##
    # Executes the current test suite recursively.
    #
    def execute
      suite = @suite
      trace = @trace

      suite.before_all.each {|b| call b }

      suite.tests.each do |test|
        suite.before_each.each {|b| call b }

        @tests.push test

        begin
          # create nested suite
          @suite = Suite.new
          @trace = []

          # populate nested suite
          call test.block, test.sandbox

          # execute nested suite
          execute

        ensure
          # restore outer values
          @suite = suite

          trace << build_exec_trace(@trace)
          @trace = trace
        end

        @tests.pop

        suite.after_each.each {|b| call b }
      end

      suite.after_all.each {|b| call b }
    end

    ##
    # Invokes the given block and debugs any
    # exceptions that may arise as a result.
    #
    def call block, sandbox = nil
      if sandbox
        sandbox.instance_eval(&block)
      else
        block.call
      end

    rescue Exception => e
      debug_uncaught_exception block, e
    end

    INTERNALS = /^#{Regexp.escape(File.dirname(__FILE__))}/ # @private

    ##
    # Keep track of Kernel#caller() bindings for use later in Dfect#debug().
    #
    # This allows us to debug block-less assertions with the same level of
    # accuracy as normal block assertions.  For example, you will be able
    # to inspect the local variables x & y in both of the following cases:
    #
    #   x = 1
    #   y = 3
    #   T { x == y }  # normal block assertion
    #   T x == y      # a block-less assertion
    #
    class << @@caller_bindings = [] # @private
      def track
        raise ArgumentError unless block_given?

        set_trace_func lambda {|event, file, line, id, binding, klass|
          case event
          when /call$/
            unshift [file, binding]

          when 'line' # update visibility to current line of execution
            shift
            unshift [file, binding]

          when /return$/
            shift
          end
        }

        yield

      ensure
        set_trace_func nil
        clear
      end
    end

    ##
    # Adds debugging information to the report.
    #
    # @param [Binding, Proc, #binding] context
    #
    #   Binding of code being debugged.  This can be either a Binding or
    #   Proc object, or nil if no binding is available---in which case,
    #   the binding of the inner-most enclosing test or hook will be used.
    #
    # @param message
    #
    #   Message describing the failure
    #   in the code being debugged.
    #
    # @param [Array<String>] backtrace
    #
    #   Stack trace corresponding to point of
    #   failure in the code being debugged.
    #
    def debug context, message = nil, backtrace = caller
      # inherit binding of nearest external stack frame
      unless context
        frame = backtrace.find {|f| f !~ INTERNALS } and
        @@caller_bindings.each do |filename, binding|
          if frame.start_with? filename
            context = binding
            break
          end
        end
      end

      # allow a Proc to be passed instead of a binding
      if context and context.respond_to? :binding
        context = context.binding
      end

      # omit internals from failure details
      backtrace = backtrace.reject {|s| s =~ INTERNALS }

      # record failure details in the report
      details = {
        # user message
        :fail => message,

        # code snippet
        :code => (
          if frame = backtrace.first
            file, line = frame.scan(/(.+?):(\d+(?=:|\z))/).first

            if source = @files[file]
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
        :vars => if context
          names = eval('::Kernel.local_variables + self.instance_variables', context, __FILE__, __LINE__)

          pairs = names.inject([]) do |pair, name|
            variable = name.to_s
            value    = eval(variable, context, __FILE__, __LINE__)

            pair.push variable.to_sym, value
          end

          Hash[*pairs]
        end,

        # stack trace
        :call => backtrace,
      }

      @trace << details

      # allow user to investigate the failure
      if @options[:debug] and context
        # show only the most helpful subset of the
        # failure details, because the rest can be
        # queried (on demand) inside the debugger
        overview = details.dup
        overview.delete :vars
        overview.delete :call
        display build_fail_trace(overview), true

        # start interactive shell for debugging
        unless defined? IRB
          require 'irb'
          IRB.setup nil
        end

        irb = IRB::Irb.new(IRB::WorkSpace.new(context))
        IRB.conf[:MAIN_CONTEXT] = irb.context
        catch(:IRB_EXIT) { irb.eval_input }

      else
        # show all failure details to the user
        display build_fail_trace(details)
      end

      nil
    end

    ##
    # Debugs the given uncaught exception inside the given context.
    #
    def debug_uncaught_exception context, exception
      @stats[:error] += 1
      debug context, exception, exception.backtrace
    end

    ##
    # Returns a report that associates the given
    # failure details with the currently running test.
    #
    def build_exec_trace details
      if @tests.empty?
        details
      else
        { @tests.last.desc => (details unless details.empty?) }
      end
    end

    ##
    # Returns a report that qualifies the given
    # failure details with the current test stack.
    #
    def build_fail_trace details
      @tests.reverse.inject(details) do |inner, outer|
        { outer.desc => inner }
      end
    end

    class Suite # @private
      attr_reader :tests, :before_each, :after_each, :before_all, :after_all

      def initialize
        @tests       = []
        @before_each = []
        @after_each  = []
        @before_all  = []
        @after_all   = []
      end

      Test = Struct.new(:desc, :block, :sandbox) # @private
    end
  end

  @options = {:debug => $DEBUG, :quiet => false}

  @stats  = Hash.new {|h,k| h[k] = 0 }
  @trace  = []
  @report = {:trace => @trace, :stats => @stats}.freeze

  @suite = class << self; Suite.new; end
  @share = {}
  @tests = []
  @files = Hash.new {|h,k| h[k] = File.readlines(k) rescue nil }

  ##
  # Allows before and after hooks to be specified via the
  # following method syntax when this module is mixed-in:
  #
  #   D .<< { puts "before all nested tests" }
  #   D .<  { puts "before each nested test" }
  #   D .>  { puts "after  each nested test" }
  #   D .>> { puts "after  all nested tests" }
  #
  D = self

  # provide mixin-able assertion methods
  methods(false).grep(/^[[:upper:]]?[[:punct:]]*$/).each do |name|
    #
    # XXX: using eval() on a string because Ruby 1.8's
    #      define_method() cannot take a block parameter
    #
    module_eval "def #{name}(*a, &b) ::#{self.name}.#{name}(*a, &b) end", __FILE__, __LINE__
  end
end
