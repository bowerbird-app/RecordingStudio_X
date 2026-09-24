# frozen_string_literal: true

require "time"

module RecordingStudio
  module X
    RateLimit = Data.define(:limit, :remaining, :reset_at) do
      def self.from_headers(headers)
        values = header_map(headers)
        limit = integer(values["x-rate-limit-limit"])
        remaining = integer(values["x-rate-limit-remaining"])
        reset = integer(values["x-rate-limit-reset"])
        return nil if limit.nil? && remaining.nil? && reset.nil?

        new(limit: limit, remaining: remaining, reset_at: reset && Time.at(reset).utc)
      end

      def self.header_map(headers)
        headers.to_h.transform_keys { |key| key.to_s.downcase }
      end

      def self.integer(value)
        return nil if value.nil? || value.to_s.empty?

        Integer(value, 10)
      rescue ArgumentError
        nil
      end

      def to_h
        {
          "limit" => limit,
          "remaining" => remaining,
          "reset_at" => reset_at&.iso8601
        }
      end
    end
  end
end
