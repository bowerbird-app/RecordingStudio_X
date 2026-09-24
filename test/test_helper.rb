# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require_relative "simplecov_helper"
require "minitest/autorun"
require "rails"
require "active_support/time"
Time.zone ||= "UTC"
require "recording_studio_x"

module RecordingStudioXTest
  module_function

  def blank_configuration!
    configuration = RecordingStudio::X::Configuration.new
    names = %i[bearer_token consumer_key consumer_secret access_token access_token_secret client_id client_secret]
    names.each do |name|
      configuration.public_send("#{name}=", nil)
    end
    configuration.transport = ->(*) { raise "unit test tried to call X" }
    RecordingStudio::X.instance_variable_set(:@configuration, configuration)
    configuration
  end
end

RecordingStudioXTest.blank_configuration!
