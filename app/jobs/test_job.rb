class TestJob < ApplicationJob
  class SimulatedJobFailure < StandardError; end
  queue_as :default

  def perform(job_data_json, attempt = 1)
    # Parsing the job data from a JSON string to a hash
    job_data = JSON.parse(job_data_json, symbolize_names: true)

    job_class = job_data[:job_class].constantize

    # Adding a delay to mimick execution
    execution_time = job_data[:execution_time]
    if execution_time
      sleep execution_time
    end

    # Adding a simulated error to test the retry logic
    if job_data[:type] == 'failure'
      raise SimulatedJobFailure, "Simulated job failure from test"
    end

    # The retry logic
    rescue SimulatedJobFailure => e
      if attempt < 3
        puts "Retrying job due to error: #{e.message} (attempt #{attempt})"
        sleep(5.seconds)
        perform(job_data_json, attempt + 1)
      else
        puts "Job failed after #{attempt} attempts, enqueuing to morgue queue"
        self.class.set(queue: 'morgue').perform_later(job_data_json)
      end
    else
      puts "Job completed successfully"
  end
end


