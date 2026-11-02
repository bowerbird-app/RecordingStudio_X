# frozen_string_literal: true

module RecordingStudio
  module X
    module HostConfigLoader
      MISSING_FILE_ERRORS = [Errno::ENOENT, Errno::ENOTDIR].freeze
      MISSING_CONFIG_PREFIX = "Could not load configuration. No such file"

      def merge_yaml_config(app)
        return unless app.respond_to?(:config_for)
        return if known_missing_yaml_file?(app)

        yaml = app.config_for(:recording_studio_x)
        RecordingStudio::X.configuration.merge!(yaml) if yaml.respond_to?(:each)
      rescue *MISSING_FILE_ERRORS
        nil
      rescue StandardError => e
        reraise_config_error(e)
      end

      def merge_x_config(app)
        return unless app.config.respond_to?(:x) && app.config.x.respond_to?(:recording_studio_x)

        xcfg = app.config.x.recording_studio_x
        if xcfg.respond_to?(:to_h)
          RecordingStudio::X.configuration.merge!(xcfg.to_h)
        else
          merge_x_pairs(xcfg)
        end
      rescue StandardError => e
        reraise_config_error(e)
      end

      private

      def merge_x_pairs(xcfg)
        hash = {}
        hash = pair_hash(xcfg) if xcfg.respond_to?(:each_pair)
        RecordingStudio::X.configuration.merge!(hash) if hash.any?
      end

      def known_missing_yaml_file?(app)
        path = yaml_config_path(app)
        path && !File.exist?(path)
      end

      def yaml_config_path(app)
        return File.join(app.root.to_s, "config", "recording_studio_x.yml") if app.respond_to?(:root) && app.root
        return unless defined?(Rails) && Rails.respond_to?(:root) && Rails.root

        Rails.root.join("config/recording_studio_x.yml").to_s
      end

      def reraise_config_error(error)
        return if missing_config_file?(error)

        log_config_load_error(error)
        raise
      end

      def missing_config_file?(error)
        error.is_a?(RuntimeError) && error.message.start_with?(MISSING_CONFIG_PREFIX)
      end

      def log_config_load_error(error)
        message = "RecordingStudio::X could not load host config: #{error.class}: #{error.message}"
        if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
          Rails.logger.error(message)
        else
          warn(message)
        end
      end

      def pair_hash(xcfg)
        hash = {}
        xcfg.each_pair { |key, value| hash[key] = value }
        hash
      end
    end
  end
end
