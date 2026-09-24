# frozen_string_literal: true

module RecordingStudio
  module X
    TokenSet = Data.define(:access_token, :refresh_token, :expires_in, :scope, :token_type) do
      def self.from_json(json)
        new(access_token: json["access_token"], refresh_token: json["refresh_token"],
            expires_in: json["expires_in"], scope: json["scope"], token_type: json["token_type"])
      end

      def to_h
        {
          "token_type" => token_type, "expires_in" => expires_in, "scope" => scope,
          "refresh_token_present" => !refresh_token.to_s.empty?
        }
      end

      def inspect
        "#<#{self.class.name} #{to_h.inspect}>"
      end
    end
  end
end
