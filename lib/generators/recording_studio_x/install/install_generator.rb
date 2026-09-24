# frozen_string_literal: true

require "rails/generators"

module RecordingStudio
  module X
    module Generators
      class InstallGenerator < Rails::Generators::Base
        source_root File.expand_path("templates", __dir__)

        namespace "recording_studio_x:install"
        desc "Install RecordingStudio::X"

        class_option :mount_path, type: :string, default: "/recording_studio_x",
                                  desc: "Route prefix used when mounting the engine"

        def mount_engine
          route %(mount RecordingStudio::X::Engine, at: "#{options[:mount_path]}")
        end

        def copy_initializer
          template "recording_studio_x_initializer.rb", "config/initializers/recording_studio_x.rb"
        end

        def show_readme
          readme "INSTALL.md" if behavior == :invoke
        end
      end
    end
  end
end
