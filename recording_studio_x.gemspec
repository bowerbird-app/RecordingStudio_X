# frozen_string_literal: true

require_relative "lib/recording_studio_x/version"

Gem::Specification.new do |spec|
  spec.name        = "recording_studio_x"
  spec.version     = RecordingStudio::X::VERSION
  spec.authors     = ["Bowerbird"]
  spec.homepage    = "https://github.com/bowerbird-app/RecordingStudio_X"
  spec.summary     = "X API access for the Recording Studio ecosystem"
  spec.description = "X-specific API access, authentication, identity, and AI tools for Recording Studio. " \
                     "Generic OAuth storage and user accounts stay in their own gems."
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/bowerbird-app/RecordingStudio_X"
  spec.metadata["changelog_uri"] = "https://github.com/bowerbird-app/RecordingStudio_X/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"].reject do |path|
      path == ".cursor" || path.start_with?(".cursor/")
    end
  end

  spec.add_dependency "rails", "~> 8.1.0"
  spec.add_dependency "recording_studio", "~> 4.2"
end
