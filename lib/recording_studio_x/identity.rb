# frozen_string_literal: true

module RecordingStudio
  module X
    Identity = Data.define(:provider, :uid, :username, :name, :image_url, :email, :raw) do
      def self.from_user(user, raw)
        new(provider: :x, uid: user.id, username: user.username, name: user.name,
            image_url: user.profile_image_url, email: raw["confirmed_email"] || raw["email"], raw: raw)
      end

      def to_h
        {
          "provider" => provider.to_s, "uid" => uid, "username" => username,
          "name" => name, "image_url" => image_url, "email" => email
        }
      end
    end
  end
end
