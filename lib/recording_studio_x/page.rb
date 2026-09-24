# frozen_string_literal: true

module RecordingStudio
  module X
    Page = Data.define(:items, :next_cursor, :rate_limit, :raw) do
      def self.from_posts(json, rate_limit)
        includes = json["includes"] || {}
        items = Array(json["data"]).filter_map { |row| Post.from_payload(row, includes: includes) }
        build(items, json, rate_limit)
      end

      def self.build(items, json, rate_limit)
        cursor = json.dig("meta", "next_token")
        cursor = nil if cursor.to_s.empty?
        new(items: items, next_cursor: cursor, rate_limit: rate_limit, raw: json)
      end

      def more?
        !next_cursor.nil?
      end

      def to_h
        {
          "items" => items.map(&:to_h), "next_cursor" => next_cursor,
          "more" => more?, "rate_limit" => rate_limit&.to_h
        }
      end
    end
  end
end
