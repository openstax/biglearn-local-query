require 'rake'

class RescuedError < StandardError
end

class TestTaskComplete < Exception
end

module TestTaskCounter
  MAX_COUNT = 10.freeze

  mattr_reader :count

  def self.reset
    @@count = 0
  end

  def self.increment
    raise 'Call TestTaskCounter.reset first' if count.nil?

    @@count = count + 1

    # Raises TestTaskComplete, aborting the Worker, after the given number of runs
    raise TestTaskComplete if count >= MAX_COUNT

    # Otherwise, raises an error that is rescued and ignored
    raise RescuedError
  end
end

namespace(:test) { task(:task) { TestTaskCounter.increment } }
