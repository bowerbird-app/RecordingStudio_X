# frozen_string_literal: true

require "uri"
require "json"

module RecordingStudio
  module X
    class Client
      def initialize(configuration: RecordingStudio::X.configuration, transport: nil)
        @configuration = configuration
        @transport = transport || configuration.transport || NetHttpTransport.new
      end

      def get(path, params, credentials:, operation:)
        perform(
          method: "GET", path: path, params: compact(params), body: nil,
          credentials: credentials, operation: operation
        )
      end

      private

      def perform(method:, path:, params:, body:, credentials:, operation:)
        started = clock
        url = url_for(path, params)
        result = @transport.call(json_env(method, url, credentials, params, body))
        payload = ErrorMapper.call(result)
        record(call_record(operation, path, credentials, { started: started, payload: payload }))
        payload
      rescue Error => e
        record(call_record(operation, path, credentials, { started: started, error: e }))
        raise
      end

      def json_env(method, url, credentials, params, body)
        {
          method: method,
          url: url,
          headers: headers_for(method, url, credentials, params),
          body: body,
          open_timeout: @configuration.open_timeout,
          read_timeout: @configuration.read_timeout,
          write_timeout: @configuration.write_timeout
        }
      end

      def headers_for(method, url, credentials, params)
        { "Accept" => "application/json" }.merge(authorization(method, url, credentials, params))
      end

      def authorization(method, url, credentials, params)
        case credentials.mode
        when :application then bearer_header(credentials)
        when :oauth2 then user_bearer(credentials)
        when :oauth1 then oauth1_header(method, url, credentials, params)
        else raise AuthenticationError, "Unknown X authentication mode"
        end
      end

      def bearer_header(credentials)
        token = credentials.bearer_token.to_s.strip
        token = @configuration.application_bearer(@transport) if token.empty?
        { "Authorization" => "Bearer #{token}" }
      end

      def user_bearer(credentials)
        token = credentials.oauth2_access_token.to_s.strip
        raise AuthenticationError, "OAuth 2 user access token is missing" if token.empty?

        { "Authorization" => "Bearer #{token}" }
      end

      def oauth1_header(method, url, credentials, params)
        missing = [credentials.consumer_key, credentials.consumer_secret, credentials.access_token,
                   credentials.access_token_secret].any? { |value| value.to_s.strip.empty? }
        raise AuthenticationError, "OAuth 1 user credentials are incomplete" if missing

        {
          "Authorization" => Oauth1Signer.header(
            method: method, url: url, params: params,
            consumer_key: credentials.consumer_key, consumer_secret: credentials.consumer_secret,
            token: credentials.access_token, token_secret: credentials.access_token_secret
          )
        }
      end

      def url_for(path, params)
        uri = URI("#{@configuration.api_origin}#{path}")
        uri.query = encode_query(params) unless params.empty?
        uri.to_s
      end

      def encode_query(params)
        params.map { |key, value| encoded_pair(key, value) }.join("&")
      end

      def encoded_pair(key, value)
        "#{Oauth1Signer.percent_encode(key)}=#{Oauth1Signer.percent_encode(value)}"
      end

      def compact(params)
        params.each_with_object({}) do |(key, value), memo|
          memo[key] = value unless value.nil? || value.to_s.empty?
        end
      end

      def record(details)
        Instrumentation.record(configuration: @configuration, **details)
      end

      def call_record(operation, path, credentials, meta)
        payload = meta[:payload]
        {
          operation: operation, endpoint: path, mode: credentials.mode, started: meta.fetch(:started),
          error: meta[:error], rate_limit: payload&.rate_limit || rate_limit_from(meta[:error]),
          result_count: payload ? Instrumentation.count(payload) : nil
        }
      end

      def rate_limit_from(error)
        error.respond_to?(:rate_limit) ? error.rate_limit : nil
      end

      def clock
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end
  end
end
