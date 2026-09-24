# frozen_string_literal: true

require "omniauth-oauth2"

module OmniAuth
  module Strategies
    class X < OmniAuth::Strategies::OAuth2
      option :name, :x
      option :client_options, {
        site: "https://api.x.com",
        authorize_url: "https://x.com/i/oauth2/authorize",
        token_url: "/2/oauth2/token"
      }
      option :pkce, true
      option :scope, RecordingStudio::X::Oauth::SIGN_IN_SCOPES.join(" ")

      uid { raw_info["id"] }

      info { RecordingStudio::X::Identity.auth_info(raw_info) }

      extra do
        { raw_info: raw_info }
      end

      def raw_info
        @raw_info ||= access_token.get(RecordingStudio::X::Identity.me_path).parsed.fetch("data")
      end

      def callback_url
        options[:redirect_uri] || (full_host + script_name + callback_path)
      end
    end
  end
end
