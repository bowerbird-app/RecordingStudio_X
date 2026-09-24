# frozen_string_literal: true

require "openssl"
require "base64"
require "securerandom"

module RecordingStudio
  module X
    class Oauth1Signer
      SIGNATURE_METHOD = "HMAC-SHA1"
      VERSION = "1.0"

      def self.header(method:, url:, params:, consumer_key:, consumer_secret:, token:, token_secret:,
                      nonce: nil, timestamp: nil)
        signed = oauth_params(consumer_key, token, nonce, timestamp)
        signature = signature_for(method, url, params.merge(signed), consumer_secret, token_secret)
        signed["oauth_signature"] = signature
        "OAuth #{header_pairs(signed)}"
      end

      def self.signature_for(method, url, params, consumer_secret, token_secret)
        base = signature_base(method, url, params)
        key = "#{percent_encode(consumer_secret)}&#{percent_encode(token_secret)}"
        digest = OpenSSL::HMAC.digest("SHA1", key, base)
        Base64.strict_encode64(digest)
      end

      def self.percent_encode(value)
        value.to_s.b.gsub(/[^A-Za-z0-9\-._~]/) { |char| format("%%%02X", char.ord) }
      end

      def self.oauth_params(consumer_key, token, nonce, timestamp)
        {
          "oauth_consumer_key" => consumer_key.to_s,
          "oauth_nonce" => nonce || SecureRandom.hex(16),
          "oauth_signature_method" => SIGNATURE_METHOD,
          "oauth_timestamp" => (timestamp || Time.now.to_i).to_s,
          "oauth_token" => token.to_s,
          "oauth_version" => VERSION
        }
      end

      def self.signature_base(method, url, params)
        [
          method.to_s.upcase,
          percent_encode(base_url(url)),
          percent_encode(normalized(params))
        ].join("&")
      end

      def self.base_url(url)
        uri = URI(url)
        port = uri.port
        default_port = uri.scheme == "https" ? 443 : 80
        host = port == default_port ? uri.host : "#{uri.host}:#{port}"
        "#{uri.scheme}://#{host}#{uri.path}"
      end

      def self.normalized(params)
        pairs = params.flat_map { |key, value| encode_pair(key, value) }
        pairs.sort.join("&")
      end

      def self.encode_pair(key, value)
        Array(value).map { |item| "#{percent_encode(key)}=#{percent_encode(item)}" }
      end

      def self.header_pairs(params)
        params.sort.map { |key, value| %(#{key}="#{percent_encode(value)}") }.join(", ")
      end
    end
  end
end
