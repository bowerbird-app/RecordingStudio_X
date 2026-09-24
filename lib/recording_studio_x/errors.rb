# frozen_string_literal: true

module RecordingStudio
  module X
    class Error < StandardError; end

    class ConfigurationError < Error; end

    class ApiError < Error
      attr_reader :status, :code, :rate_limit

      def initialize(message = nil, status: nil, code: nil, rate_limit: nil)
        @status = status
        @code = code
        @rate_limit = rate_limit
        super(message)
      end
    end

    class AuthenticationError < ApiError; end
    class AuthorizationError < ApiError; end
    class NotFoundError < ApiError; end
    class InvalidRequestError < ApiError; end
    class InvalidResponseError < ApiError; end

    class RateLimitError < ApiError
      def initialize(message = nil, status: 429, code: nil, rate_limit: nil)
        super
      end
    end

    class NetworkError < Error; end
  end
end
