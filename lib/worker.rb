class Worker
  EXCLUDED_EXCEPTIONS = [ SystemExit ]

  def initialize(task_name_string)
    @task_name_string = task_name_string
  end

  def task
    @task ||= Rake::Task[@task_name_string]
  end

  def run_once
    log(:debug) { 'Reenabling task...' }
    task.reenable

    log(:debug) { 'Invoking task...' }
    task.invoke
  rescue Exception => ex
    log(:fatal) { "#{ex.class.name}: #{ex.message}\n#{ex.backtrace.join("\n")}" }

    Raven.capture_exception(ex) unless EXCLUDED_EXCEPTIONS.include? ex.class

    raise ex
  end

  def run(run_every = 1.second)
    start_time = Time.current.freeze
    log(:info) { "Started at #{start_time}" }

    1.upto(Float::INFINITY).each do |iteration|
      run_once

      wake_up_at = start_time + iteration * run_every
      sleep_interval = wake_up_at - Time.current
      if sleep_interval > 0
        log(:debug) { "#{sleep_interval} second(s) ahead of schedule - sleeping..." }
        sleep sleep_interval
      else
        log(:debug) { "#{-sleep_interval} second(s) behind schedule - skipping sleep" }
      end
    end
  end

  protected

  def log(level, &block)
    Rails.logger.tagged(@task_name_string, 'Worker') { |logger| logger.public_send(level, &block) }
  end
end
