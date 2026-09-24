# frozen_string_literal: true

RecordingStudio::X.configure do |config|
  config.bearer_token = ENV.fetch("x_bearer_token", nil) if ENV.key?("x_bearer_token")
  config.consumer_key = ENV.fetch("x_consumer_key", nil) if ENV.key?("x_consumer_key")
  config.consumer_secret = ENV.fetch("x_consumer_key_secret", nil) if ENV.key?("x_consumer_key_secret")
  config.client_id = ENV.fetch("x_client_id", nil) if ENV.key?("x_client_id")
  config.client_secret = ENV.fetch("x_client_secret", nil) if ENV.key?("x_client_secret")
end
