# frozen_string_literal: true

require "base64"

module RecordingStudio
  module X
    class AppBearer
      PATH = "/oauth2/token"

      def initialize
        @lock = Mutex.new
        @token = nil
      end

      def clear
        @lock.synchronize { @token = nil }
      end

      def fetch(configuration, transport)
        configured = configuration.bearer_token.to_s.strip
        return configured unless configured.empty?

        @lock.synchronize { @token ||= request(configuration, transport) }
      end

      private

      def request(configuration, transport)
        unless configuration.oauth1_app_configured?
          raise ConfigurationError, "Application credentials are not configured"
        end

        result = transport.call(token_env(configuration))
        token = ErrorMapper.call(result).json["access_token"]
        return token unless token.to_s.empty?

        raise AuthenticationError.new("X did not return an application bearer token", status: result.status)
      end

      def token_env(configuration)
        {
          method: "POST",
          url: "#{configuration.api_origin}#{PATH}",
          headers: token_headers(configuration),
          body: "grant_type=client_credentials",
          open_timeout: configuration.open_timeout,
          read_timeout: configuration.read_timeout,
          write_timeout: configuration.write_timeout
        }
      end

      def token_headers(configuration)
        {
          "Authorization" => basic(configuration.consumer_key, configuration.consumer_secret),
          "Content-Type" => "application/x-www-form-urlencoded;charset=UTF-8",
          "Accept" => "application/json"
        }
      end

      def basic(key, secret)
        raw = "#{Oauth1Signer.percent_encode(key)}:#{Oauth1Signer.percent_encode(secret)}"
        "Basic #{Base64.strict_encode64(raw)}"
      end
    end
  end
end
