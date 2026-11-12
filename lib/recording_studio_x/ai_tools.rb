# frozen_string_literal: true

require "recording_studio_x/ai_tool_catalog"

module RecordingStudio
  module X
    module AiTools
      VERSION = 1

      def self.register!
        return unless defined?(::RecordingStudioAI)

        catalog.each do |tool|
          ::RecordingStudioAI.tools.register(**tool.fetch(:registration), override: true)
        end
      end

      def self.catalog
        AiToolCatalog.rows.map { |spec| entry(spec) }
      end

      def self.entry(spec)
        capability = Capabilities.fetch(spec.fetch(:operation))
        spec.merge(capability_fields(capability), registration: registration(spec, capability))
      end

      def self.capability_fields(capability)
        {
          access: capability.access, authentication: capability.authentication,
          scopes: capability.scopes, side_effects: capability.side_effects?
        }
      end

      def self.registration(spec, capability)
        copy_fields(spec).merge(safety(capability), executor: executor(spec.fetch(:key)))
      end

      def self.copy_fields(spec)
        {
          key: spec.fetch(:key), version: VERSION, name: spec.fetch(:name),
          description: spec.fetch(:description), use_when: spec.fetch(:use_when),
          do_not_use_when: spec.fetch(:do_not_use_when), parameters: spec.fetch(:parameters),
          returns: spec.fetch(:returns), cost: :low, latency: :slow,
          executor_label: "RecordingStudio::X #{spec.fetch(:operation)}"
        }
      end

      def self.safety(capability)
        { read_only: capability.read?, destructive: false, requires_confirmation: false, idempotent: true }
      end

      def self.executor(key)
        {
          x_search: ->(arguments, _context) { search_page(arguments) },
          x_get_post: ->(arguments, _context) { Reads.post(arguments.fetch("id")).to_h },
          x_get_user: ->(arguments, _context) { user_record(arguments).to_h },
          x_get_user_posts: ->(arguments, _context) { user_posts_page(arguments) }
        }.fetch(key)
      end

      def self.search_page(arguments)
        Reads.search(query: arguments.fetch("query"), max_results: arguments["max_results"],
                     cursor: arguments["cursor"]).to_h
      end

      def self.user_record(arguments)
        Reads.user(username: arguments["username"], id: arguments["id"])
      end

      def self.user_posts_page(arguments)
        Reads.user_posts(arguments.fetch("id"), max_results: arguments["max_results"],
                                                cursor: arguments["cursor"], exclude: arguments["exclude"]).to_h
      end
    end
  end
end
