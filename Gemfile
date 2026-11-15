# frozen_string_literal: true

source "https://rubygems.org"

gemspec

# recording_studio is not published to RubyGems; resolve the gemspec pin from GitHub.
gem "recording_studio", github: "bowerbird-app/RecordingStudio", tag: "v7.0.0"

# FlatPack is not on RubyGems.
gem "flat_pack", github: "bowerbird-app/flatpack", tag: "v0.1.376"

gem "devise"
gem "puma", "8.1.0"
gem "sprockets-rails"

group :development, :test do
  gem "debug"
  gem "simplecov", require: false
end

group :development do
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
end
