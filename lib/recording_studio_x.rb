# frozen_string_literal: true

require "recording_studio"
require "recording_studio_x/version"
require "recording_studio_x/errors"
require "recording_studio_x/rate_limit"
require "recording_studio_x/capability"
require "recording_studio_x/credentials"
require "recording_studio_x/oauth1_signer"
require "recording_studio_x/transport"
require "recording_studio_x/error_mapper"
require "recording_studio_x/app_bearer"
require "recording_studio_x/configuration"
require "recording_studio_x/instrumentation"
require "recording_studio_x/client"
require "recording_studio_x/models"
require "recording_studio_x/reads"
require "recording_studio_x/oauth"
require "recording_studio_x/oauth_token"
require "recording_studio_x/diagnostics"
require "recording_studio_x/ai_tools"
require "recording_studio_x/engine"

module RecordingStudio
  module X
    class << self
      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield configuration if block_given?
      end

      def reset_configuration!
        @configuration = Configuration.new
      end

      def search(...)
        Reads.search(...)
      end

      def post(...)
        Reads.post(...)
      end

      def user(...)
        Reads.user(...)
      end

      def user_posts(...)
        Reads.user_posts(...)
      end

      def identity(...)
        Reads.identity(...)
      end

      def capabilities
        Capabilities::LIST
      end

      def capability(operation)
        Capabilities.fetch(operation)
      end

      def diagnose(...)
        Diagnostics.report(...)
      end

      def authorize_url(...)
        Oauth.authorize_url(...)
      end

      def exchange_code(...)
        Oauth.exchange_code(...)
      end

      def refresh(...)
        Oauth.refresh(...)
      end
    end
  end
end
