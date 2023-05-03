# config/initializers/active_job_pubsub_adapter.rb
require 'active_job'
require_relative '../../lib/active_job/queue_adapters/pubsub_adapter'

ActiveJob::Base.queue_adapter = ActiveJob::QueueAdapters::PubsubAdapter.new
