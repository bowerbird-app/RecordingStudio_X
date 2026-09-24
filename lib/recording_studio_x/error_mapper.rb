# frozen_string_literal: true

require "json"

module RecordingStudio
  module X
    class ErrorMapper
      STATUS_CLASS = {
        400 => InvalidRequestError,
        401 => AuthenticationError,
        403 => AuthorizationError,
        404 => NotFoundError,
        429 => RateLimitError
      }.freeze

      def self.call(result)
        json = parse(result.body)
        rate_limit = RateLimit.from_headers(result.headers)
        return ApiPayload.new(json, rate_limit) if result.status.between?(200, 299)

        raise_error(result.status, json, rate_limit)
      end

      def self.parse(body)
        return {} if body.to_s.strip.empty?

        parsed = JSON.parse(body)
        raise InvalidResponseError, "X response JSON was not an object" unless parsed.is_a?(Hash)

        parsed
      rescue JSON::ParserError
        raise InvalidResponseError, "X response was not JSON"
      end

      def self.raise_error(status, json, rate_limit)
        klass = STATUS_CLASS.fetch(status, ApiError)
        raise klass.new(message(json, status), status: status, code: code(json), rate_limit: rate_limit)
      end

      def self.message(json, status)
        first_message(json) || json["detail"] || json["title"] || "X API request failed (#{status})"
      end

      def self.first_message(json)
        first = json["errors"].is_a?(Array) ? json["errors"].first : nil
        return unless first.is_a?(Hash)

        first["message"] || first["detail"] || first["title"]
      end

      def self.code(json)
        first = json["errors"].is_a?(Array) ? json["errors"].first : nil
        return first["code"] || first["type"] if first.is_a?(Hash)

        json["type"]
      end
    end

    ApiPayload = Data.define(:json, :rate_limit)
  end
end
