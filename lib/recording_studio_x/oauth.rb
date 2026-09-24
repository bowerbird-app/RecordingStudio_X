# frozen_string_literal: true

require "base64"
require "digest"
require "securerandom"

module RecordingStudio
  module X
    module Oauth
      AUTHORIZE_URL = "https://x.com/i/oauth2/authorize"
      TOKEN_PATH = "/2/oauth2/token"
      SIGN_IN_SCOPES = %w[tweet.read users.read users.email offline.access].freeze
      CONNECT_SCOPES = %w[
        tweet.read tweet.write users.read users.email like.read like.write
        follows.read follows.write offline.access
      ].freeze

      module_function

      def pkce
        verifier = SecureRandom.urlsafe_base64(96).delete("=")[0, 64]
        { verifier: verifier, challenge: s256(verifier), method: "S256" }
      end

      def s256(verifier)
        Base64.urlsafe_encode64(Digest::SHA256.digest(verifier.to_s), padding: false)
      end

      def authorize_url(redirect_uri:, state:, code_challenge:, scopes: SIGN_IN_SCOPES,
                        code_challenge_method: "S256", client_id: nil,
                        configuration: RecordingStudio::X.configuration)
        id = required_client_id(client_id, configuration)
        challenge = { scopes: scopes, method: code_challenge_method }
        params = authorize_params(id, redirect_uri, state, code_challenge, challenge)
        "#{AUTHORIZE_URL}?#{encode(params)}"
      end

      def exchange_code(code:, redirect_uri:, code_verifier:, client_id: nil, client_secret: nil,
                        configuration: RecordingStudio::X.configuration)
        id = required_client_id(client_id, configuration)
        form = {
          "grant_type" => "authorization_code",
          "code" => code,
          "redirect_uri" => redirect_uri,
          "code_verifier" => code_verifier,
          "client_id" => id
        }
        token_request(form, id, client_secret || configuration.client_secret, configuration)
      end

      def refresh(refresh_token:, client_id: nil, client_secret: nil,
                  configuration: RecordingStudio::X.configuration)
        id = required_client_id(client_id, configuration)
        form = {
          "grant_type" => "refresh_token",
          "refresh_token" => refresh_token,
          "client_id" => id
        }
        token_request(form, id, client_secret || configuration.client_secret, configuration)
      end

      def provider
        {
          "provider" => "x", "label" => "X", "authorize_url" => AUTHORIZE_URL,
          "token_url" => "https://api.x.com#{TOKEN_PATH}", "identity_endpoint" => "GET /2/users/me",
          "pkce" => "S256", "sign_in_scopes" => SIGN_IN_SCOPES, "connect_scopes" => CONNECT_SCOPES
        }
      end

      def install_strategy!
        return unless defined?(OmniAuth::Strategies::OAuth2)

        require "recording_studio_x/omniauth_strategy"
      end

      def encode(params)
        params.map { |key, value| encoded_pair(key, value) }.join("&")
      end

      def encoded_pair(key, value)
        "#{Oauth1Signer.percent_encode(key)}=#{Oauth1Signer.percent_encode(value)}"
      end

      def authorize_params(client_id, redirect_uri, state, code_challenge, options)
        {
          "response_type" => "code", "client_id" => client_id, "redirect_uri" => redirect_uri,
          "scope" => Array(options[:scopes]).join(" "), "state" => state,
          "code_challenge" => code_challenge, "code_challenge_method" => options[:method]
        }
      end

      def required_client_id(client_id, configuration)
        id = client_id || configuration.client_id
        raise ConfigurationError, "X OAuth client id is not configured" if id.to_s.strip.empty?

        id
      end
    end
  end
end
