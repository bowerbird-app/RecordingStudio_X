# frozen_string_literal: true

require "recording_studio_x/api/handlers"
require "recording_studio_x/api/catalog"

module RecordingStudio
  module X
    module Api
      OPENAPI_TAGS = ["X"].freeze

      class << self
        def openapi(action, description, parameters)
          {
            summary: "#{OPENAPI_TAGS.first} - #{action}",
            description: description,
            tags: OPENAPI_TAGS,
            parameters: parameters
          }
        end

        def query_param(name, description, required: false, type: "string")
          { name: name, in: "query", required: required, description: description, schema: { type: type } }
        end

        def path_param(name, description)
          { name: name, in: "path", required: true, description: description, schema: { type: "string" } }
        end
      end

      ENDPOINTS = Catalog.rows.freeze

      class << self
        def register!
          return unless defined?(RecordingStudioApi)

          RecordingStudioApi.configuration.each_api do |api|
            ENDPOINTS.each { |endpoint| register_named_endpoint(endpoint, api) }
          end
        end

        private

        def register_named_endpoint(endpoint, api)
          existing = RecordingStudioApi.registered_endpoint(endpoint[:name], api: api.name)
          if existing
            return if our_handler?(existing.handler, endpoint[:handler])

            raise RecordingStudioApi::ConfigurationError,
                  "API endpoint #{endpoint[:name]} is already registered with a different handler"
          end

          RecordingStudioApi.register_endpoint(endpoint[:name], api: api.name, **endpoint.except(:name))
        end

        def our_handler?(existing, handler)
          return true if existing == handler
          return false unless existing.respond_to?(:name) && handler.respond_to?(:name)

          existing.name.present? && existing.name == handler.name
        end
      end
    end
  end
end
