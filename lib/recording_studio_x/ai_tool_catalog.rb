# frozen_string_literal: true

module RecordingStudio
  module X
    module AiToolCatalog
      def self.rows
        [search, post, user, user_posts]
      end

      def self.search
        spec(:x_search, :search, "Search X posts", search_copy, search_parameters)
      end

      def self.post
        spec(:x_get_post, :get_post, "Get an X post", post_copy, post_parameters)
      end

      def self.user
        spec(:x_get_user, :get_user, "Get an X user", user_copy, user_parameters)
      end

      def self.user_posts
        spec(:x_get_user_posts, :get_user_posts, "Get posts by an X user", user_posts_copy, user_posts_parameters)
      end

      def self.spec(key, operation, name, copy, parameters)
        {
          key: key, operation: operation, name: name, description: copy[:description],
          use_when: copy[:use_when], do_not_use_when: copy[:do_not_use_when],
          parameters: parameters, returns: copy[:returns]
        }
      end

      def self.search_copy
        {
          description: "Searches public posts from the last 7 days. X query syntax is passed through.",
          use_when: "The question needs recent public posts on X.",
          do_not_use_when: "The question needs a write on X, a full archive, or a private account action.",
          returns: "A page of posts with next_cursor, more, and rate_limit. Does not fetch every page."
        }
      end

      def self.post_copy
        {
          description: "Loads one public post by id.",
          use_when: "A post id is already known.",
          do_not_use_when: "The post id is unknown. Search first.",
          returns: "The post id, text, url, author, created_at, and public metrics."
        }
      end

      def self.user_copy
        {
          description: "Loads a public user by username or id.",
          use_when: "A username or user id is known.",
          do_not_use_when: "Neither a username nor a user id is known.",
          returns: "The user id, username, name, profile url, description, and profile image."
        }
      end

      def self.user_posts_copy
        {
          description: "Loads a page of posts authored by a user id.",
          use_when: "The user id is known and recent posts are needed.",
          do_not_use_when: "Only a username is known. Look up the user first. Do not use this to post.",
          returns: "A page of that user's posts with next_cursor, more, and rate_limit."
        }
      end

      def self.post_parameters
        [{ name: :id, type: :string, required: true, description: "X post id." }]
      end

      def self.search_parameters
        [
          { name: :query, type: :string, required: true, description: "X recent-search query." },
          { name: :max_results, type: :integer, required: false, description: "Page size from 10 to 100." },
          { name: :cursor, type: :string, required: false, description: "next_cursor from the previous page." }
        ]
      end

      def self.user_parameters
        [
          { name: :username, type: :string, required: false, description: "X username without @." },
          { name: :id, type: :string, required: false, description: "X user id." }
        ]
      end

      def self.user_posts_parameters
        [
          { name: :id, type: :string, required: true, description: "X user id." },
          { name: :max_results, type: :integer, required: false, description: "Page size from 5 to 100." },
          { name: :cursor, type: :string, required: false, description: "next_cursor from the previous page." },
          { name: :exclude, type: :string, required: false, description: "Comma-separated replies and retweets." }
        ]
      end
    end
  end
end
