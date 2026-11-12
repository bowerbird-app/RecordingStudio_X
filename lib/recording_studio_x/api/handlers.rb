# frozen_string_literal: true

module RecordingStudio
  module X
    module Api
      module Handlers
        module_function

        def authorize!(context)
          context.access_grant.authorize!(recording: context.root_recording, role: :view)
        end

        def read_call(context)
          authorize!(context)
          yield
        rescue InvalidRequestError => e
          raise invalid_input(e)
        end

        def invalid_input(error)
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
