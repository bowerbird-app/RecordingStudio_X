# frozen_string_literal: true

module RecordingStudio
  module X
    class ApplicationController < ActionController::Base
      protect_from_forgery with: :exception

      recording_studio_layout { RecordingStudio::X.configuration.layout }
    end
  end
end
