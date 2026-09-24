# frozen_string_literal: true

require "recording_studio_x/configuration_status"

module RecordingStudio
  module X
    class Configuration
      DEFAULT_OPEN_TIMEOUT = 5
      DEFAULT_READ_TIMEOUT = 10
      DEFAULT_WRITE_TIMEOUT = 5
      DEFAULT_ORIGIN = "https://api.x.com"

      include ConfigurationStatus

      attr_reader :hooks, :bearer_token, :consumer_key, :consumer_secret
      attr_accessor :transport, :instrumentation_enabled, :access_token, :access_token_secret,
                    :client_id, :client_secret
      attr_writer :open_timeout, :read_timeout, :write_timeout, :api_origin

      def initialize
        assign_environment
        assign_defaults
      end

      def bearer_token=(value)
        @bearer_token = value
        @app_bearer.clear
      end

      def consumer_key=(value)
        @consumer_key = value
        @app_bearer.clear
      end

      def consumer_secret=(value)
        @consumer_secret = value
        @app_bearer.clear
      end

      def open_timeout
        @open_timeout || DEFAULT_OPEN_TIMEOUT
      end

      def read_timeout
        @read_timeout || DEFAULT_READ_TIMEOUT
      end

      def write_timeout
        @write_timeout || DEFAULT_WRITE_TIMEOUT
      end

      def api_origin
        @api_origin || DEFAULT_ORIGIN
      end

      def application_bearer(transport)
        @app_bearer.fetch(self, transport)
      end

      private

      def assign_environment
        @bearer_token = ENV.fetch("x_bearer_token", nil)
        @consumer_key = ENV.fetch("x_consumer_key", nil)
        @consumer_secret = ENV.fetch("x_consumer_key_secret", nil)
        use_consumer_secret_fallback
        @access_token = ENV.fetch("x_access_token", nil)
        @access_token_secret = ENV.fetch("x_access_token_secret", nil)
        @client_id = ENV.fetch("x_client_id", nil)
        @client_secret = ENV.fetch("x_client_secret", nil)
      end

      def use_consumer_secret_fallback
        return unless @consumer_secret.to_s.strip.empty?

        @consumer_secret = ENV.fetch("x_consumer_secret", nil)
      end

      def assign_defaults
        @open_timeout = DEFAULT_OPEN_TIMEOUT
        @read_timeout = DEFAULT_READ_TIMEOUT
        @write_timeout = DEFAULT_WRITE_TIMEOUT
        @api_origin = DEFAULT_ORIGIN
        @instrumentation_enabled = true
        @transport = nil
        @hooks = RecordingStudio::Hooks.new
        @app_bearer = AppBearer.new
      end
    end
  end
end
