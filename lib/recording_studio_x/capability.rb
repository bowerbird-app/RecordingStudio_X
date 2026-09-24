# frozen_string_literal: true

module RecordingStudio
  module X
    Capability = Data.define(
      :operation, :access, :authentication, :scopes, :endpoint, :implemented
    ) do
      def read?
        access == :read
      end

      def write?
        access == :write
      end

      def side_effects?
        write?
      end

      def allows?(mode)
        key = mode.to_sym
        return authentication.include?(:application) if key == :application
        return authentication.include?(:user) if %i[oauth1 oauth2].include?(key)

        false
      end

      def to_h
        {
          "operation" => operation.to_s,
          "access" => access.to_s,
          "authentication" => authentication.map(&:to_s),
          "scopes" => scopes,
          "endpoint" => endpoint,
          "implemented" => implemented,
          "side_effects" => side_effects?
        }
      end
    end

    module Capabilities
      def self.define(operation, access:, authentication:, endpoint:, scopes: [], implemented: true)
        Capability.new(
          operation: operation,
          access: access,
          authentication: Array(authentication).map(&:to_sym).freeze,
          scopes: scopes.map(&:to_s).freeze,
          endpoint: endpoint,
          implemented: implemented
        )
      end

      USER_READ = %w[tweet.read users.read].freeze
      POST_WRITE = %w[tweet.read users.read tweet.write].freeze

      LIST = [
        define(:search, access: :read, authentication: %i[application user], scopes: USER_READ,
                        endpoint: "GET /2/tweets/search/recent"),
        define(:get_post, access: :read, authentication: %i[application user], scopes: USER_READ,
                          endpoint: "GET /2/tweets/:id"),
        define(:get_user, access: :read, authentication: %i[application user], scopes: USER_READ,
                          endpoint: "GET /2/users/:id"),
        define(:get_user_posts, access: :read, authentication: %i[application user], scopes: USER_READ,
                                endpoint: "GET /2/users/:id/tweets"),
        define(:identity, access: :read, authentication: :user, scopes: USER_READ,
                          endpoint: "GET /2/users/me"),
        define(:create_post, access: :write, authentication: :user, scopes: POST_WRITE,
                             endpoint: "POST /2/tweets", implemented: false),
        define(:reply, access: :write, authentication: :user, scopes: POST_WRITE,
                       endpoint: "POST /2/tweets", implemented: false),
        define(:delete_post, access: :write, authentication: :user, scopes: POST_WRITE,
                             endpoint: "DELETE /2/tweets/:id", implemented: false),
        define(:repost, access: :write, authentication: :user, scopes: POST_WRITE,
                        endpoint: "POST /2/users/:id/retweets", implemented: false),
        define(:undo_repost, access: :write, authentication: :user, scopes: POST_WRITE,
                             endpoint: "DELETE /2/users/:id/retweets/:tweet_id", implemented: false),
        define(:like, access: :write, authentication: :user, scopes: %w[like.write users.read tweet.read],
                      endpoint: "POST /2/users/:id/likes", implemented: false),
        define(:unlike, access: :write, authentication: :user, scopes: %w[like.write users.read tweet.read],
                        endpoint: "DELETE /2/users/:id/likes/:tweet_id", implemented: false),
        define(:follow, access: :write, authentication: :user, scopes: %w[follows.write users.read],
                        endpoint: "POST /2/users/:id/following", implemented: false),
        define(:unfollow, access: :write, authentication: :user, scopes: %w[follows.write users.read],
                          endpoint: "DELETE /2/users/:source_user_id/following/:target_user_id", implemented: false)
      ].freeze

      BY_OPERATION = LIST.to_h { |capability| [capability.operation, capability] }.freeze

      def self.fetch(operation)
        BY_OPERATION.fetch(operation.to_sym)
      end

      def self.implemented
        LIST.select(&:implemented)
      end
    end

    DEFERRED = [
      {
        "name" => "webhooks",
        "status" => "deferred",
        "note" => "V2 webhooks cover account activity, X activity, and filtered-stream delivery. " \
                  "CRC and HTTPS are required."
      },
      {
        "name" => "filtered_stream",
        "status" => "deferred",
        "note" => "GET /2/tweets/search/stream is a persistent app-only connection."
      },
      {
        "name" => "full_archive_search",
        "status" => "deferred",
        "note" => "GET /2/tweets/search/all is limited to pay-per-use and Enterprise."
      }
    ].freeze
  end
end
