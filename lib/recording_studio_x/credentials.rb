# frozen_string_literal: true

module RecordingStudio
  module X
    class Credentials
      MODES = %i[application oauth1 oauth2].freeze

      attr_reader :mode, :bearer_token, :consumer_key, :consumer_secret,
                  :access_token, :access_token_secret, :oauth2_access_token,
                  :refresh_token, :scopes, :client_id, :client_secret

      def self.application(bearer_token: nil, consumer_key: nil, consumer_secret: nil)
        new(mode: :application, bearer_token: bearer_token, consumer_key: consumer_key,
            consumer_secret: consumer_secret)
      end

      def self.oauth1(consumer_key:, consumer_secret:, access_token:, access_token_secret:)
        new(mode: :oauth1, consumer_key: consumer_key, consumer_secret: consumer_secret,
            access_token: access_token, access_token_secret: access_token_secret)
      end

      def self.oauth2(access_token:, refresh_token: nil, scopes: [], client_id: nil, client_secret: nil)
        new(mode: :oauth2, oauth2_access_token: access_token, refresh_token: refresh_token,
            scopes: scopes, client_id: client_id, client_secret: client_secret)
      end

      def self.from_connection(connection, configuration:)
        return nil if connection.nil?
        return connection if connection.is_a?(self)
        return connection.to_x_credentials if connection.respond_to?(:to_x_credentials)
        return nil unless connection.respond_to?(:to_h)

        build_from_hash(connection.to_h, configuration)
      end

      def self.build_from_hash(raw, configuration)
        data = raw.to_h.transform_keys(&:to_sym)
        return application(bearer_token: data[:bearer_token]) if present?(data[:bearer_token])
        return oauth1_from(data, configuration) if oauth1_hash?(data)
        return oauth2_from(data, configuration) if user_token(data)

        raise AuthenticationError, "X could not read credentials from the connection"
      end

      def self.oauth1_hash?(data)
        present?(data[:access_token_secret]) || present?(data[:oauth_token_secret])
      end

      def self.oauth1_from(data, configuration)
        oauth1(
          consumer_key: data[:consumer_key] || configuration.consumer_key,
          consumer_secret: data[:consumer_secret] || configuration.consumer_secret,
          access_token: data[:access_token] || data[:oauth_token],
          access_token_secret: data[:access_token_secret] || data[:oauth_token_secret]
        )
      end

      def self.oauth2_from(data, configuration)
        oauth2(
          access_token: user_token(data),
          refresh_token: data[:refresh_token],
          scopes: Array(data[:scopes]),
          client_id: data[:client_id] || configuration.client_id,
          client_secret: data[:client_secret] || configuration.client_secret
        )
      end

      def self.user_token(data)
        data[:oauth2_access_token] || data[:token] || data[:access_token]
      end

      def self.present?(value)
        !value.to_s.strip.empty?
      end

      def self.for_capability(capability, connection:, credentials:, configuration:)
        resolved = credentials || from_connection(connection, configuration: configuration)
        resolved ||= configuration.default_credentials
        raise ConfigurationError, "X credentials are not configured" if resolved.nil?
        raise AuthenticationError, "#{capability.operation} does not accept #{resolved.mode} credentials" unless
          capability.allows?(resolved.mode)

        resolved
      end

      def initialize(mode:, **attrs)
        @mode = mode
        assign_attributes(attrs)
        @scopes = Array(attrs.fetch(:scopes, [])).map(&:to_s).freeze
        freeze
      end

      def user?
        %i[oauth1 oauth2].include?(mode)
      end

      def inspect
        "#<#{self.class.name} mode=#{mode}>"
      end

      private

      def assign_attributes(attrs)
        names = %i[bearer_token consumer_key consumer_secret access_token access_token_secret]
        names += %i[oauth2_access_token refresh_token client_id client_secret]
        names.each { |name| instance_variable_set(:"@#{name}", attrs[name]) }
      end
    end
  end
end
