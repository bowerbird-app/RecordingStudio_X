# frozen_string_literal: true

module RecordingStudio
  module X
    module ConfigurationStatus
      def instrumentation_enabled?
        @instrumentation_enabled.nil? || @instrumentation_enabled
      end

      def bearer_configured?
        present?(@bearer_token)
      end

      def oauth1_app_configured?
        present?(@consumer_key) && present?(@consumer_secret)
      end

      def oauth1_user_configured?
        oauth1_app_configured? && present?(@access_token) && present?(@access_token_secret)
      end

      def oauth2_client_configured?
        present?(@client_id) && present?(@client_secret)
      end

      def application_credentials?
        bearer_configured? || oauth1_app_configured?
      end

      def default_credentials
        return application_credentials if application_credentials?

        nil
      end

      def to_h
        credential_flags.merge(runtime_flags)
      end

      def inspect
        "#<#{self.class.name} #{to_h.inspect}>"
      end

      def merge!(hash)
        return unless hash.respond_to?(:each)

        hash.each do |key, value|
          setter = "#{key}="
          public_send(setter, value) if respond_to?(setter)
        end
      end

      private

      def credential_flags
        {
          application_bearer_token: flag(bearer_configured?),
          oauth1_app_credentials: flag(oauth1_app_configured?),
          oauth1_user_credentials: flag(oauth1_user_configured?),
          oauth2_client_credentials: flag(oauth2_client_configured?)
        }
      end

      def runtime_flags
        {
          api_origin: api_origin,
          open_timeout: open_timeout,
          read_timeout: read_timeout,
          write_timeout: write_timeout,
          instrumentation_enabled: instrumentation_enabled?,
          hooks_registered: hooks.registered_counts
        }
      end

      def present?(value)
        !value.to_s.strip.empty?
      end

      def flag(configured)
        configured ? "configured" : "missing"
      end

      def application_credentials
        Credentials.application(
          bearer_token: @bearer_token,
          consumer_key: @consumer_key,
          consumer_secret: @consumer_secret
        )
      end
    end
  end
end
