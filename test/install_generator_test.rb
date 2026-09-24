# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "tmpdir"
require "generators/recording_studio_x/install/install_generator"

class InstallGeneratorTest < Minitest::Test
  INSTALL_TEMPLATE_PATH = File.expand_path(
    "../lib/generators/recording_studio_x/install/templates/INSTALL.md",
    __dir__
  )

  def build_generator(destination_root, options = {})
    RecordingStudio::X::Generators::InstallGenerator.new(
      [],
      options,
      destination_root: destination_root
    )
  end

  def test_mount_engine_uses_configured_mount_path
    generator = build_generator("/tmp", mount_path: "/addons/x")
    routes = []

    generator.stub(:route, ->(value) { routes << value }) do
      generator.mount_engine
    end

    assert_equal ["mount RecordingStudio::X::Engine, at: \"/addons/x\""], routes
  end

  def test_copy_initializer_writes_configuration_without_secret_values
    Dir.mktmpdir do |dir|
      generator = build_generator(dir)
      generator.copy_initializer
      path = File.join(dir, "config/initializers/recording_studio_x.rb")
      source = File.read(path)

      assert_includes source, "RecordingStudio::X.configure"
      assert_includes source, 'ENV.fetch("x_consumer_key", nil)'
      refute_match(/x_consumer_key_secret", nil\) = "/, source)
    end
  end

  def test_show_readme_displays_install_guide_for_invoke_behavior
    generator = build_generator("/tmp")
    shown_templates = []

    generator.stub(:behavior, :invoke) do
      generator.stub(:readme, ->(template) { shown_templates << template }) do
        generator.show_readme
      end
    end

    assert_equal ["INSTALL.md"], shown_templates
  end

  def test_install_guide_says_there_are_no_migrations
    install_guide = File.read(INSTALL_TEMPLATE_PATH)

    assert_includes install_guide, "recording_studio_x:install"
    assert_equal "recording_studio_x:install", RecordingStudio::X::Generators::InstallGenerator.namespace
    assert_includes install_guide, "does not run database migrations"
    refute_includes install_guide, "db:migrate"
  end
end
