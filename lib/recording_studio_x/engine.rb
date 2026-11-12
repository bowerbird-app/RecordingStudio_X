# frozen_string_literal: true

module RecordingStudio
  module X
    class Engine < ::Rails::Engine
      isolate_namespace RecordingStudio::X
      engine_name "recording_studio_x"

      class << self
        def apply_model_extensions(target)
          apply_extensions(target, extensions_for(:model, extension_keys_for(target)))
        end

        def apply_controller_extensions(target)
          apply_extensions(target, extensions_for(:controller, extension_keys_for(target)))
        end

        def merge_yaml_config(app)
          return unless app.respond_to?(:config_for)

          yaml = load_yaml(app)
          RecordingStudio::X.configuration.merge!(yaml) if yaml.respond_to?(:each)
        rescue StandardError
          nil
        end

        def merge_x_config(app)
          return unless app.config.respond_to?(:x) && app.config.x.respond_to?(:recording_studio_x)

          xcfg = app.config.x.recording_studio_x
          if xcfg.respond_to?(:to_h)
            RecordingStudio::X.configuration.merge!(xcfg.to_h)
          else
            merge_x_pairs(xcfg)
          end
        end

        private

        def load_yaml(app)
          app.config_for(:recording_studio_x)
        rescue StandardError
          nil
        end

        def merge_x_pairs(xcfg)
          hash = {}
          hash = pair_hash(xcfg) if xcfg.respond_to?(:each_pair)
          RecordingStudio::X.configuration.merge!(hash) if hash.any?
        rescue StandardError
          nil
        end

        def pair_hash(xcfg)
          hash = {}
          xcfg.each_pair { |key, value| hash[key] = value }
          hash
        end

        def extensions_for(kind, names)
          hooks = RecordingStudio::X.configuration.hooks
          Array(names).flat_map { |name| extension_list(hooks, kind, name) }
        end

        def extension_list(hooks, kind, name)
          return hooks.model_extensions_for(name) if kind == :model

          hooks.controller_extensions_for(name)
        end

        def apply_extensions(target, extensions)
          return unless target

          applied = target.instance_variable_get(:@recording_studio_x_applied_extensions) || {}.compare_by_identity
          extensions.flatten.compact.each { |extension| apply_once(target, applied, extension) }
          target.instance_variable_set(:@recording_studio_x_applied_extensions, applied)
        end

        def apply_once(target, applied, extension)
          return if applied[extension]

          target.class_eval(&extension)
          applied[extension] = true
        end

        def extension_keys_for(target)
          [target.name, target.name&.demodulize].compact.uniq.map(&:to_sym)
        end
      end

      initializer "recording_studio_x.before_initialize", before: "recording_studio_x.load_config" do |_app|
        RecordingStudio::X.configuration.hooks.run(:before_initialize, self)
      end

      initializer "recording_studio_x.load_config" do |app|
        Engine.merge_yaml_config(app)
        Engine.merge_x_config(app)
        RecordingStudio::X.configuration.hooks.run(:on_configuration, RecordingStudio::X.configuration)
      end

      initializer "recording_studio_x.after_initialize", after: "recording_studio_x.load_config" do |_app|
        RecordingStudio::X.configuration.hooks.run(:after_initialize, self)
      end

      initializer "recording_studio_x.prepare" do
        config.to_prepare do
          AiTools.register!
          Oauth.install_strategy!
        end
      end

      initializer "recording_studio_x.apply_model_extensions" do
        config.to_prepare do
          next unless defined?(ActiveRecord::Base)

          ActiveRecord::Base.descendants.each do |model|
            next if model.abstract_class?

            Engine.apply_model_extensions(model)
          end
        end
      end

      initializer "recording_studio_x.apply_controller_extensions" do
        config.to_prepare do
          next unless defined?(ActionController::Base)

          ActionController::Base.descendants.each do |controller|
            Engine.apply_controller_extensions(controller)
          end
        end
      end
    end
  end
end
