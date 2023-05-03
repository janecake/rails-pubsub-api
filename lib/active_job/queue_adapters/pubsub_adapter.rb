require 'json'
require 'active_job'
require_relative '../../pubsub'

module ActiveJob
  module QueueAdapters
    class PubsubAdapter
      # Setting constants for project ID, topic prefix, and subscription prefix
      PROJECT_ID = ENV['PROJECT_ID']
      TOPIC_PREFIX = 'activejob-'
      SUBSCRIPTION_PREFIX = 'activejob-sub-'

      # Initializing a new Pubsub client with project ID and emulator host
      def initialize
        # Seting the emulator host to localhost:8085 if not provided in environment variable
        emulator_host = ENV['PUBSUB_EMULATOR_HOST'] || 'localhost:8085'
        @pubsub = Pubsub.new(project_id: PROJECT_ID, emulator_host: emulator_host)
      end

      # Deserializing job data to create a new job instance
      def deserialize_job(job_data)
        deserialize(job_data)
      end

      # Enqueueing a job by publishing it to a Pub/Sub topic with the queue name
      def enqueue(job)
        # Getting the topic for the queue name
        topic = get_topic(job.queue_name)
        # Publishing the serialized job instance to the topic
        topic.publish(serialize(job))
      end

      # Enqueueing a job with a scheduled delay by publishing it to a Pub/Sub topic with the queue name
      def enqueue_at(job, timestamp)
        # Calculating the delay in seconds
        delay_seconds = timestamp - Time.current.to_i
        # Getting the topic for the queue name
        topic = get_topic(job.queue_name)
        # Publishing the serialized job instance to the topic with a schedule time
        topic.publish(serialize(job), schedule_time: delay_seconds)
      end

      # Deserializing the job data and perform the job instance
      def perform(job_instance)
        # Serializing the job instance as JSON data
        job_data = serialize(job_instance)
        # Passing the job_data as an argument to the perform method of the job instance
        job_instance.perform(job_data)
      end
      
      # Retrying a job by publishing it to a Pub/Sub topic with a scheduled delay
      def retry_job(job, wait:, **options)
        puts "retrying from pubsub"
        # Calculating the delay in seconds
        delay_seconds = wait.to_i
        # Getting the topic for the queue name
        topic = get_topic(job.queue_name)
        # Publishing the serialized job instance to the topic with a scheduled time attribute
        topic.publish(serialize(job), attributes: { 'scheduled_at': (Time.current + delay_seconds).to_i.to_s })
      end

      private

      # Getting a topic for a queue name with a prefix
      def get_topic(queue_name)
        topic_name = "#{TOPIC_PREFIX}#{queue_name}"
        # Get the topic if it exists, otherwise create a new topic
        @pubsub.topic(topic_name) || @pubsub.create_topic(topic_name)
      end

      # Serializing a job instance as JSON data
      def serialize(job)
        job_data = job.serialize
        JSON.dump(job_data)
      end

      # Deserializing job data from a JSON string and create a new job instance with the data
      def deserialize(job_data)
        job_data = JSON.parse(job_data, symbolize_names: true)
        # Getting the job class from the job data and instantiate a new job instance with the data as arguments
        job_class = job_data[:job_class].constantize
        job_instance = job_class.new(job_data)
        # Setting the arguments for the job instance as a JSON string
        job_instance.arguments = [job_data.to_json]
        job_instance
      end         
    end
  end
end
