class HomeController < ApplicationController
  def index
    @search = SearchRequest.from_params(params)
    @query = @search.query
    return if @query.blank?
    return @error = @search.error if @search.error

    @page = RecordingStudio::X.search(**@search.arguments)
  rescue RecordingStudio::X::Error => e
    @error = search_error(e)
  end

  private

  def search_error(error)
    case error
    when RecordingStudio::X::ConfigurationError
      "X is not set up on this app yet."
    when RecordingStudio::X::RateLimitError
      "X asked us to wait. Try again in a moment."
    when RecordingStudio::X::NetworkError
      "X did not answer. Try again."
    when RecordingStudio::X::AuthorizationError
      "X refused this app. Attach the developer app to a Project, then try again."
    when RecordingStudio::X::AuthenticationError
      "X did not accept these credentials."
    else
      "X could not run that search."
    end
  end
end
