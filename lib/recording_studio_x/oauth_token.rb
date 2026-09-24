# frozen_string_literal: true

module RecordingStudio
  module X
    module Oauth
      module_function

      def token_request(form, client_id, client_secret, configuration)
        transport = configuration.transport || NetHttpTransport.new
        result = transport.call(token_env(form, client_id, client_secret, configuration))
        token = TokenSet.from_json(ErrorMapper.call(result).json)
        return token unless token.access_token.to_s.empty?

        raise AuthenticationError.new("X did not return a user access token", status: result.status)
      end

      def token_env(form, client_id, client_secret, configuration)
        {
          method: "POST", url: "#{configuration.api_origin}#{TOKEN_PATH}",
          headers: token_headers(client_id, client_secret), body: encode(form),
          open_timeout: configuration.open_timeout, read_timeout: configuration.read_timeout,
          write_timeout: configuration.write_timeout
        }
      end

      def token_headers(client_id, client_secret)
        headers = {
          "Accept" => "application/json",
          "Content-Type" => "application/x-www-form-urlencoded;charset=UTF-8"
        }
        return headers if client_secret.to_s.strip.empty?

        raw = "#{Oauth1Signer.percent_encode(client_id)}:#{Oauth1Signer.percent_encode(client_secret)}"
        headers.merge("Authorization" => "Basic #{Base64.strict_encode64(raw)}")
      end
    end
  end
end
