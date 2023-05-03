# frozen_string_literal: true

require("google/cloud/pubsub")

# Pubsub is a simple wrapper around the Google Cloud Pub/Sub client library.
class Pubsub
  def initialize(project_id:, emulator_host: nil)
    # Storing the project ID and emulator host as instance variables
    @project_id = project_id
    @emulator_host = emulator_host
  end

  # Getting a topic by name. If the topic does not exist, create it.
  def topic(name)
    client.topic(name) || client.create_topic(name)
  end

  # Getting a subscription by name and project.
  def subscription(name, project:)
    client.subscription(name, project: project)
  end

  private

  # Getting a Google Cloud Pub/Sub client instance.
  def client
    # Creating a new client instance with project ID, emulator host, and credentials.
    @client ||= Google::Cloud::PubSub.new(
      project_id: @project_id,
      endpoint: @emulator_host,
      credentials: @emulator_host ? :this_channel_is_insecure : nil
    )
  end
end
