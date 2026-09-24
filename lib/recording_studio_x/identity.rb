# frozen_string_literal: true

module RecordingStudio
  module X
    Identity = Data.define(:provider, :uid, :username, :name, :image_url, :email, :raw) do
      def self.from_user(user, raw)
        new(provider: :x, uid: user.id, username: user.username, name: user.name,
            image_url: user.profile_image_url, email: address(raw), raw: raw)
      end

      def self.auth_info(raw)
        info = { name: raw["name"], nickname: raw["username"], image: raw["profile_image_url"] }
        email = address(raw)
        return info if email.nil?

        info.merge(email: email, email_verified: true)
      end

      def self.me_path
        "/2/users/me?user.fields=id,name,username,profile_image_url,description,confirmed_email"
      end

      def self.address(raw)
        value = raw["confirmed_email"].to_s.strip
        value = raw["email"].to_s.strip if value.empty?
        value.empty? ? nil : value
      end
      private_class_method :address

      def to_h
        {
          "provider" => provider.to_s, "uid" => uid, "username" => username,
          "name" => name, "image_url" => image_url, "email" => email
        }
      end
    end
  end
end
