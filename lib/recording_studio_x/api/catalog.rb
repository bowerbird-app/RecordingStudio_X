# frozen_string_literal: true

module RecordingStudio
  module X
    module Api
      module Catalog
        def self.rows
          [search, post, user, user_posts]
        end

        def self.search
          endpoint(name: :x_search, path: "x/search", handler: Handlers::Search,
                   openapi: search_openapi, fields: search_fields)
        end

        def self.post
          endpoint(name: :x_get_post, path: "x/posts/:id", handler: Handlers::Post,
                   openapi: post_openapi, fields: post_fields)
        end

        def self.user
          endpoint(name: :x_get_user, path: "x/users", handler: Handlers::User,
                   openapi: user_openapi, fields: user_fields)
        end

        def self.user_posts
          endpoint(
            name: :x_get_user_posts, path: "x/users/:id/posts", handler: Handlers::UserPosts,
            openapi: user_posts_openapi, fields: user_posts_fields
          )
        end

        def self.endpoint(name:, path:, handler:, openapi:, fields:, http_verb: :get)
          {
            name: name, http_verb: http_verb, path: path, handler: handler, openapi: openapi,
            input_contract: { reject_unknown: false, fields: fields }
          }
        end

        def self.search_openapi
          Api.openapi(
            "Search X posts",
            "Searches public posts from the last 7 days. X query syntax is passed through. One page.",
            [
              Api.query_param("query", "X recent-search query.", required: true),
              Api.query_param("max_results", "Page size from 10 to 100.", type: "integer"),
              Api.query_param("cursor", "next_cursor from the previous page.")
            ]
          )
        end

        def self.post_openapi
          Api.openapi("Get an X post", "Loads one public post by id.", [Api.path_param("id", "X post id.")])
        end

        def self.user_openapi
          Api.openapi(
            "Get an X user",
            "Loads a public user by username or id. Pass one of those, not both.",
            [Api.query_param("username", "X username without @."), Api.query_param("id", "X user id.")]
          )
        end

        def self.user_posts_openapi
          Api.openapi(
            "Get posts by an X user",
            "Loads a page of posts authored by a user id.",
            [
              Api.path_param("id", "X user id."),
              Api.query_param("max_results", "Page size from 5 to 100.", type: "integer"),
              Api.query_param("cursor", "next_cursor from the previous page."),
              Api.query_param("exclude", "Comma-separated replies and retweets.")
            ]
          )
        end

        def self.search_fields
          {
            query: { type: :string, required: true, allow_blank: false, description: "X recent-search query." },
            max_results: { type: :integer, required: false, description: "Page size from 10 to 100." },
            cursor: { type: :string, required: false, description: "next_cursor from the previous page." }
          }
        end

        def self.post_fields
          { id: { type: :string, required: true, allow_blank: false, description: "X post id." } }
        end

        def self.user_fields
          {
            username: { type: :string, required: false, description: "X username without @." },
            id: { type: :string, required: false, description: "X user id." }
          }
        end

        def self.user_posts_fields
          {
            id: { type: :string, required: true, allow_blank: false, description: "X user id." },
            max_results: { type: :integer, required: false, description: "Page size from 5 to 100." },
            cursor: { type: :string, required: false, description: "next_cursor from the previous page." },
            exclude: { type: :string, required: false, description: "Comma-separated replies and retweets." }
          }
        end
      end
    end
  end
end
