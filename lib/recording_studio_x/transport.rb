# frozen_string_literal: true

require "net/http"
require "openssl"
require "uri"

module RecordingStudio
  module X
    HttpResult = Data.define(:status, :headers, :body)

    class NetHttpTransport
      def call(env)
        uri = URI(env.fetch(:url))
        response = execute(uri, env)
        HttpResult.new(status: response.code.to_i, headers: response.each_header.to_h, body: response.body.to_s)
      rescue Timeout::Error, SocketError, SystemCallError, OpenSSL::SSL::SSLError, EOFError => e
        raise NetworkError, e.class.name
      end

      private

      def execute(uri, env)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        assign_timeouts(http, env)
        http.request(build_request(uri, env))
      end

      def assign_timeouts(http, env)
        http.open_timeout = env[:open_timeout]
        http.read_timeout = env[:read_timeout]
        http.write_timeout = env[:write_timeout]
      end

      def build_request(uri, env)
        request = request_class(env.fetch(:method)).new(uri)
        env.fetch(:headers).each { |key, value| request[key] = value }
        request.body = env[:body] if env[:body]
        request
      end

      def request_class(method)
        Net::HTTP.const_get(method.to_s.capitalize)
      end
    end
  end
end
