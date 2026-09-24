# frozen_string_literal: true

require "active_support/notifications"

module RecordingStudio
  module X
    module Instrumentation
      EVENT = "request.recording_studio_x"

      def self.publish(payload)
        ActiveSupport::Notifications.instrument(EVENT, payload)
      end

      def self.record(configuration:, **fields)
        return unless configuration.instrumentation_enabled?

        publish(event_payload(fields))
      end

      def self.count(payload)
        data = payload.json["data"]
        return data.length if data.is_a?(Array)
        return 1 if data.is_a?(Hash)

        0
      end

      def self.event_payload(fields)
        {
          operation: fields[:operation], endpoint: fields[:endpoint],
          authentication: fields[:mode].to_s, request_count: 1,
          duration_ms: elapsed(fields[:started]), result_count: fields[:result_count],
          error: fields[:error]&.class&.name, rate_limit: fields[:rate_limit]&.to_h
        }
      end

      def self.elapsed(started)
        ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round
      end
    end
  end
end
