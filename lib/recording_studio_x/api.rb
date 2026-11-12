# frozen_string_literal: true

require "recording_studio_x/api/handlers"
require "recording_studio_x/api/catalog"

module RecordingStudio
  module X
    module Api
      VIEW_ROLE = :view
      OPENAPI_TAGS = ["X"].freeze

      class << self
        def openapi(summary, description, parameters)
          { summary: summary, description: description, tags: OPENAPI_TAGS, parameters: parameters }
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
          return unless available?

          api_names.each { |api| register_on(api) }
          true
        end

        def available?
          defined?(RecordingStudioApi) && RecordingStudioApi.respond_to?(:register_endpoint)
        end

        def authorize!(context)
          Handlers.authorize!(context)
        end

        private

        def api_names
          configuration = RecordingStudioApi.configuration if RecordingStudioApi.respond_to?(:configuration)
          return [:public] unless configuration.respond_to?(:each_api)

          configuration.each_api.map { |definition| definition.respond_to?(:name) ? definition.name : :public }
        end

        def register_on(api)
          ENDPOINTS.each { |endpoint| register_endpoint(endpoint, api) }
        end

        def register_endpoint(endpoint, api)
          name = endpoint.fetch(:name)
          return if already_registered?(name, api)

          RecordingStudioApi.register_endpoint(name, api: api, **endpoint_kwargs(endpoint))
        end

        def already_registered?(name, api)
          return false unless RecordingStudioApi.respond_to?(:registered_endpoint)

          RecordingStudioApi.registered_endpoint(name, api: api).present?
        end

        def endpoint_kwargs(endpoint)
          kwargs = endpoint.except(:name)
          return kwargs unless accepts_required_role?

          kwargs.merge(required_role: VIEW_ROLE)
        end

        def accepts_required_role?
          RecordingStudioApi.method(:register_endpoint).parameters.any? do |type, name|
            type == :keyrest || (name == :required_role && %i[key keyreq].include?(type))
          end
        end
      end
    end
  end
end
