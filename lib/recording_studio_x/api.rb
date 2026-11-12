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
            ENDPOINTS.each do |endpoint|
              existing = RecordingStudioApi.registered_endpoint(endpoint[:name], api: api.name)
              next if existing && existing.handler == endpoint[:handler]

              RecordingStudioApi.register_endpoint(endpoint[:name], api: api.name, **endpoint.except(:name))
            end
          end
        end
      end
    end
  end
end
