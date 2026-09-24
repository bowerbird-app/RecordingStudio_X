# frozen_string_literal: true

require "test_helper"

class LiveSmokeTest < Minitest::Test
  def setup
    skip "Set RECORDING_STUDIO_X_LIVE=1 for read-only X calls" unless ENV["RECORDING_STUDIO_X_LIVE"] == "1"
    @configuration = RecordingStudio::X::Configuration.new
    @configuration.transport = nil
  end

  def test_application_auth_reads_a_public_user
    credentials = application_credentials
    skip "Application credentials are not configured" if credentials.nil?

    user = public_user(credentials)

    assert_equal "XDevelopers", user.username
    refute_nil user.id
  end

  def test_application_auth_reads_one_post_and_a_small_search
    credentials = application_credentials
    skip "Application credentials are not configured" if credentials.nil?

    user = public_user(credentials)
    page = RecordingStudio::X.user_posts(
      user.id, max_results: 5, credentials: credentials, configuration: @configuration
    )
    skip "XDevelopers returned no posts" if page.items.empty?

    post = RecordingStudio::X.post(page.items.first.id, credentials: credentials, configuration: @configuration)
    search = RecordingStudio::X.search(
      query: "from:XDevelopers",
      max_results: 10,
      credentials: credentials,
      configuration: @configuration
    )

    assert_equal page.items.first.id, post.id
    assert_operator search.items.length, :<=, 10
  end

  def test_oauth1_user_context_reads_a_public_user
    skip "OAuth 1 user credentials are not configured" unless @configuration.oauth1_user_configured?

    credentials = RecordingStudio::X::Credentials.oauth1(
      consumer_key: @configuration.consumer_key,
      consumer_secret: @configuration.consumer_secret,
      access_token: @configuration.access_token,
      access_token_secret: @configuration.access_token_secret
    )
    user = public_user(credentials)

    assert_equal "XDevelopers", user.username
  end

  private

  def public_user(credentials)
    RecordingStudio::X.user(username: "XDevelopers", credentials: credentials, configuration: @configuration)
  rescue RecordingStudio::X::AuthorizationError => e
    raise unless e.status == 403 && e.code.to_s.include?("client-forbidden")

    skip "X returned HTTP 403 client-forbidden. Attach the developer app to a Project."
  end

  def application_credentials
    return nil unless @configuration.application_credentials?

    RecordingStudio::X::Credentials.application(
      bearer_token: @configuration.bearer_token,
      consumer_key: @configuration.consumer_key,
      consumer_secret: @configuration.consumer_secret
    )
  end
end
