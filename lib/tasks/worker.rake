# frozen_string_literal: true
require 'google/cloud/pubsub'
require_relative '../pubsub'
require_relative '../active_job/queue_adapters/pubsub_adapter'

namespace :worker do
  desc 'Run the worker'
  task run: :environment do
    puts 'Worker starting...'

    # Set up the Google Cloud Pub/Sub client
    project_id = ENV['PROJECT_ID']
    emulator_host = ENV['PUBSUB_EMULATOR_HOST'] || 'localhost:8085'
    pubsub = Pubsub.new(project_id: project_id, emulator_host: emulator_host)

    # Set up the PubsubAdapter
    pubsub_adapter = ActiveJob::QueueAdapters::PubsubAdapter.new

    # Check if the topic and subscription exist, create them if they don't
    topic_name = 'zhanna_topic'
    topic = pubsub.topic(topic_name)

    subscription_name = 'zhanna_test_subscription'
    subscription = pubsub.subscription(subscription_name, project: project_id)
    subscription ||= topic.subscribe(subscription_name)

    begin
      loop do
        puts "Polling for messages..."
        # Pull messages from the subscription
        subscription.pull(immediate: false).each do |message|
          begin
            puts "Received message: #{message.message_id}"
            puts "Message payload: #{message.data}"

            # Deserialize the job data and get the job instance
            job_instance = pubsub_adapter.deserialize_job(message.data)

            # Perform the job with the given job instance
            begin
              job_instance.perform(*job_instance.arguments)

              # Acknowledge the message to remove it from the subscription
              message.acknowledge!
            end
          end

          # Sleep for a short duration before polling for new messages
          sleep(5)
        end
      end
    rescue Google::Cloud::Error => e
      puts "Google Cloud Pub/Sub error: #{e.message}"
    end
  end
end