# test_tasks.rake
desc "Enqueues random test jobs"
task 'worker:test' => :environment do
  require 'google/cloud/pubsub'
  
  pubsub = Google::Cloud::Pubsub.new(project_id: ENV['PROJECT_ID'])
  topic_name = 'zhanna_topic'
  
  # Check if the topic exists, create it if it doesn't
  topic = pubsub.topic(topic_name)
  topic ||= pubsub.create_topic(topic_name)

  # Generate 5 messages per second
  loop do
    5.times do
      random_string = (0...8).map { ('a'..'z').to_a[rand(26)] }.join
      message = {
        id: random_string,
        type: ['success', 'failure'].sample, # This line randomly selects 'success' or 'failure'
        job_class: 'TestJob',
        execution_time: rand(0..5)
      }
      topic.publish(message.to_json, ordering_key: message[:id])
      puts "Enqueued message: #{message}"
    end
    sleep 1
  end
end





