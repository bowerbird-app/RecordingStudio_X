# frozen_string_literal: true

require "time"

module RecordingStudio
  module X
    Post = Data.define(:id, :text, :url, :author, :created_at, :metrics, :raw) do
      def self.from_payload(data, includes: {})
        return nil unless data.is_a?(Hash)

        author = author_for(data["author_id"], includes)
        new(id: data["id"].to_s, text: data["text"].to_s, url: post_url(data["id"], author), author: author,
            created_at: parse_time(data["created_at"]), metrics: data["public_metrics"] || {}, raw: data)
      end

      def self.author_for(author_id, includes)
        users = includes.is_a?(Hash) ? includes["users"] : nil
        match = Array(users).find { |user| user["id"].to_s == author_id.to_s }
        User.from_payload(match)
      end

      def self.post_url(id, author)
        return nil if id.to_s.empty?
        return "https://x.com/#{author.username}/status/#{id}" if author&.username.to_s != ""

        "https://x.com/i/web/status/#{id}"
      end

      def self.parse_time(value)
        return nil if value.to_s.empty?

        Time.iso8601(value)
      rescue ArgumentError
        nil
      end

      def to_h
        {
          "id" => id, "text" => text, "url" => url, "author" => author&.to_h,
          "created_at" => created_at&.iso8601, "metrics" => metrics
        }
      end
    end
  end
end
