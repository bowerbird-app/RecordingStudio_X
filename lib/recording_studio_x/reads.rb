# frozen_string_literal: true

module RecordingStudio
  module X
    module Fields
      POST = %w[author_id conversation_id created_at entities lang public_metrics].join(",")
      USER = %w[created_at description id name profile_image_url public_metrics url username verified].join(",")
      EXPANSIONS = "author_id"
    end

    module Reads
      module_function

      def search(query:, max_results: nil, cursor: nil, start_time: nil, end_time: nil, sort_order: nil,
                 archive: false, credentials: nil, connection: nil, configuration: RecordingStudio::X.configuration)
        require_query(query)
        path, operation = search_target(archive)
        params = search_params(query:, max_results:, cursor:, start_time:, end_time:, sort_order:)
        page(get(path, params, operation, auth(credentials, connection, configuration)))
      end

      def search_target(archive)
        return ["/2/tweets/search/all", :archive_search] if archive

        ["/2/tweets/search/recent", :search]
      end

      def search_params(query:, max_results:, cursor:, start_time:, end_time:, sort_order:)
        field_params.merge(
          "query" => query,
          "max_results" => max_results,
          "next_token" => cursor,
          "start_time" => start_time,
          "end_time" => end_time,
          "sort_order" => sort_order
        )
      end

      def post(id, credentials: nil, connection: nil, configuration: RecordingStudio::X.configuration)
        payload = get("/2/tweets/#{id}", field_params, :get_post, auth(credentials, connection, configuration))
        found(Post.from_payload(payload.json["data"], includes: payload.json["includes"] || {}), payload)
      end

      def user(id: nil, username: nil, credentials: nil, connection: nil,
               configuration: RecordingStudio::X.configuration)
        path = user_path(id, username)
        payload = get(path, { "user.fields" => Fields::USER }, :get_user, auth(credentials, connection, configuration))
        found(User.from_payload(payload.json["data"]), payload)
      end

      def user_posts(id, max_results: nil, cursor: nil, exclude: nil, start_time: nil, end_time: nil,
                     credentials: nil, connection: nil, configuration: RecordingStudio::X.configuration)
        params = field_params.merge(
          "max_results" => max_results,
          "pagination_token" => cursor,
          "exclude" => exclude_param(exclude),
          "start_time" => start_time,
          "end_time" => end_time
        )
        page(get("/2/users/#{id}/tweets", params, :get_user_posts, auth(credentials, connection, configuration)))
      end

      def identity(credentials: nil, connection: nil, configuration: RecordingStudio::X.configuration)
        fields = { "user.fields" => "#{Fields::USER},confirmed_email" }
        payload = get("/2/users/me", fields, :identity, auth(credentials, connection, configuration))
        user = found(User.from_payload(payload.json["data"]), payload)
        Identity.from_user(user, payload.json["data"])
      end

      def get(path, params, operation, access)
        capability = Capabilities.fetch(operation)
        resolved = Credentials.for_capability(
          capability,
          connection: access[:connection],
          credentials: access[:credentials],
          configuration: access[:configuration]
        )
        Client.new(configuration: access[:configuration]).get(path, params, credentials: resolved, operation: operation)
      end

      def auth(credentials, connection, configuration)
        { credentials: credentials, connection: connection, configuration: configuration }
      end

      def field_params
        {
          "tweet.fields" => Fields::POST,
          "expansions" => Fields::EXPANSIONS,
          "user.fields" => Fields::USER
        }
      end

      def page(payload)
        Page.from_posts(payload.json, payload.rate_limit)
      end

      def found(record, payload)
        return record if record

        problem = Array(payload.json["errors"]).first
        message = problem.is_a?(Hash) ? (problem["detail"] || problem["title"] || problem["message"]) : nil
        raise NotFoundError.new(
          message || "X record was not found",
          status: payload_status(problem),
          code: problem.is_a?(Hash) ? problem["type"] : nil,
          rate_limit: payload.rate_limit
        )
      end

      def payload_status(problem)
        problem.is_a?(Hash) ? problem["status"] : nil
      end

      def require_query(query)
        raise InvalidRequestError, "query is required" if query.to_s.strip.empty?
      end

      def user_path(id, username)
        raise InvalidRequestError, "Pass a user id or a username" if id.to_s.empty? && username.to_s.empty?
        raise InvalidRequestError, "Pass a user id or a username, not both" if !id.to_s.empty? && !username.to_s.empty?

        return "/2/users/#{id}" unless id.to_s.empty?

        "/2/users/by/username/#{username}"
      end

      def exclude_param(exclude)
        return nil if exclude.nil?
        return exclude.join(",") if exclude.is_a?(Array)

        exclude
      end
    end
  end
end
