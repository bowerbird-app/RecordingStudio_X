# frozen_string_literal: true

module RecordingStudio
  module X
    class ApplicationController < ActionController::Base
      recording_studio_layout { RecordingStudio::X.configuration.layout }
    end
  end
end
