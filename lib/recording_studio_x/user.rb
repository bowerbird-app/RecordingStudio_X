# frozen_string_literal: true

module RecordingStudio
  module X
    User = Data.define(:id, :username, :name, :url, :description, :profile_image_url, :raw) do
      def self.from_payload(data)
        return nil unless data.is_a?(Hash)

        username = data["username"].to_s
        new(id: data["id"].to_s, username: username, name: data["name"].to_s, url: profile_url(username),
            description: data["description"], profile_image_url: data["profile_image_url"], raw: data)
      end

      def self.profile_url(username)
        username.empty? ? nil : "https://x.com/#{username}"
      end

      def to_h
        {
          "id" => id, "username" => username, "name" => name, "url" => url,
          "description" => description, "profile_image_url" => profile_image_url
        }
      end
    end
  end
end
