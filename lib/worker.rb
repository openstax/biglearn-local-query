class Worker
  EXCLUDED_EXCEPTIONS = [ SystemExit ]

  def initialize(task_name_string)
    @task_name_string = task_name_string
  end

  def task
    @task ||= Rake::Task[@task_name_string]
  end

  def run(run_every = 1.second)
    start_time = Time.current.freeze
    log(:info) { "Started at #{start_time}" }

    (0..Float::INFINITY).each do |iteration|
      if iteration > 0
        sleep_interval = start_time + iteration * run_every - Time.current
        if sleep_interval > 0
          log(:debug) { "#{sleep_interval} second(s) ahead of schedule - sleeping..." }
          sleep sleep_interval
        else
          log(:debug) { "#{-sleep_interval} second(s) behind schedule - skipping sleep" }
        end
      end

      log(:debug) { 'Reenabling task...' }
      task.reenable

      log(:debug) { 'Invoking task...' }
      task.invoke
    rescue Exception => ex
      unless EXCLUDED_EXCEPTIONS.include? ex.class
        log(:fatal) { "#{ex.class.name}: #{ex.message}\n#{ex.backtrace.join("\n")}" }

        Raven.capture_exception(ex)
      end

      # We ignore any StandardErrors and attempt to continue with the next iteration
      # Non-StandardErrors (such as SystemExit) are allowed to bubble up and terminate the worker
      raise(ex) unless ex.is_a? StandardError
    end
  end

  protected

  def log(level, &block)
    Rails.logger.tagged(@task_name_string, 'Worker') { |logger| logger.public_send(level, &block) }
  end
end
