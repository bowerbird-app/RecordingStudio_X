# frozen_string_literal: true

module RecordingStudio
  module X
    module Diagnostics
      module_function

      def report(probe: false, configuration: RecordingStudio::X.configuration)
        result = {
          "application_bearer_token" => flag(configuration.bearer_configured?),
          "oauth1_app_credentials" => flag(configuration.oauth1_app_configured?),
          "oauth1_user_credentials" => flag(configuration.oauth1_user_configured?),
          "oauth2_client_credentials" => flag(configuration.oauth2_client_configured?)
        }
        result["probe"] = probe_default(configuration) if probe
        result
      end

      def flag(configured)
        configured ? "configured" : "missing"
      end

      def probe_default(configuration)
        credentials = configuration.default_credentials
        return { "ok" => false, "error" => "ConfigurationError" } if credentials.nil?

        user = Reads.user(username: "XDevelopers", credentials: credentials, configuration: configuration)
        { "ok" => true, "authentication" => credentials.mode.to_s, "username" => user.username }
      rescue Error => e
        { "ok" => false, "authentication" => credentials.mode.to_s, "error" => e.class.name, "status" => status_of(e) }
      end

      def status_of(error)
        error.respond_to?(:status) ? error.status : nil
      end
    end
  end
end
