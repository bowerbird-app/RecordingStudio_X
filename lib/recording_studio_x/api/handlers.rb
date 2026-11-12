# frozen_string_literal: true

module RecordingStudio
  module X
    module Api
      module Handlers
        DENIED = "API access grant is not authorized for this capability"

        module_function

        def authorize!(context)
          grant = context.respond_to?(:access_grant) ? context.access_grant : nil
          recording = context.respond_to?(:root_recording) ? context.root_recording : nil
          if grant.respond_to?(:authorize!)
            grant.authorize!(recording: recording, role: VIEW_ROLE)
            return
          end

          return if accessible_view?(actor_from(context), recording)

          raise_denied!
        end

        def accessible_view?(actor, recording)
          defined?(RecordingStudioAccessible) &&
            RecordingStudioAccessible.authorized?(actor: actor, recording: recording, role: VIEW_ROLE)
        end

        def actor_from(context)
          return context.initiator if context.respond_to?(:initiator) && context.initiator
          return context.executor if context.respond_to?(:executor)

          nil
        end

        def raise_denied!
          raise RecordingStudioApi::AuthorizationError, DENIED if defined?(RecordingStudioApi::AuthorizationError)

          raise AuthorizationError, DENIED
        end

        def read_call(context)
          authorize!(context)
          yield
        rescue InvalidRequestError => e
          raise invalid_input(e)
        end

        def invalid_input(error)
          return error unless defined?(RecordingStudioApi::InvalidActionInputError)

          RecordingStudioApi::InvalidActionInputError.new(error.message)
        end

        class Search
          def self.call(context)
            Handlers.read_call(context) do
              params = context.params
              RecordingStudio::X.search(
                query: params[:query],
                max_results: params[:max_results],
                cursor: params[:cursor]
              ).to_h
            end
          end
        end

        class Post
          def self.call(context)
            Handlers.read_call(context) { RecordingStudio::X.post(context.params[:id]).to_h }
          end
        end

        class User
          def self.call(context)
            Handlers.read_call(context) do
              params = context.params
              RecordingStudio::X.user(username: params[:username], id: params[:id]).to_h
            end
          end
        end

        class UserPosts
          def self.call(context)
            Handlers.read_call(context) do
              params = context.params
              RecordingStudio::X.user_posts(
                params[:id],
                max_results: params[:max_results],
                cursor: params[:cursor],
                exclude: params[:exclude]
              ).to_h
            end
          end
        end
      end
    end
  end
end
