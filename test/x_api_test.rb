# frozen_string_literal: true

require "test_helper"
require "digest"
require "base64"

class XApiTest < Minitest::Test
  RATE_HEADERS = {
    "x-rate-limit-limit" => "450",
    "x-rate-limit-remaining" => "449",
    "x-rate-limit-reset" => "1893456000"
  }.freeze

  def setup
    @configuration = RecordingStudio::X::Configuration.new
    names = %i[bearer_token consumer_key consumer_secret access_token access_token_secret client_id client_secret]
    names.each do |name|
      @configuration.public_send("#{name}=", nil)
    end
    @configuration.bearer_token = "app-bearer"
  end

  def test_search_returns_posts_cursor_and_rate_limit_without_fetching_the_next_page
    transport, calls = scripted([search_response])
    @configuration.transport = transport

    page = RecordingStudio::X.search(query: '"BowerBird"', max_results: 10, configuration: @configuration)

    assert_equal 1, calls.length
    assert_includes calls.first[:url], "/2/tweets/search/recent?"
    assert_includes calls.first[:url], "query=%22BowerBird%22"
    assert_includes calls.first[:url], "max_results=10"
    assert_equal "Bearer app-bearer", calls.first[:headers]["Authorization"]
    assert_equal "1001", page.items.first.id
    assert_equal "Hello", page.items.first.text
    assert_equal "https://x.com/bowerbird/status/1001", page.items.first.url
    assert_equal "bowerbird", page.items.first.author.username
    assert_equal "https://x.com/bowerbird", page.items.first.author.url
    assert_equal({ "like_count" => 2 }, page.items.first.metrics)
    assert_equal "next-1", page.next_cursor
    assert_equal true, page.more?
    assert_equal 450, page.rate_limit.limit
    assert_equal 449, page.rate_limit.remaining
    assert_equal Time.utc(2030, 1, 1), page.rate_limit.reset_at
    refute page.to_h.key?("raw")
    assert_equal "Hello", page.items.first.raw["text"]
  end

  def test_search_sends_the_previous_cursor_as_next_token
    transport, calls = scripted([search_response("meta" => {})])
    @configuration.transport = transport

    page = RecordingStudio::X.search(query: "from:XDevelopers", cursor: "cursor-9", configuration: @configuration)

    assert_includes calls.first[:url], "next_token=cursor-9"
    assert_equal false, page.more?
    assert_nil page.next_cursor
  end

  def test_blank_search_query_does_not_call_x
    @configuration.transport = ->(*) { raise "called X" }

    error = assert_raises(RecordingStudio::X::InvalidRequestError) do
      RecordingStudio::X.search(query: "  ", configuration: @configuration)
    end

    assert_equal "query is required", error.message
  end

  def test_post_lookup_uses_the_web_status_url_without_an_author
    body = { "data" => { "id" => "55", "text" => "Solo", "created_at" => "2026-01-02T03:04:05Z" } }
    transport, calls = scripted([json_result(200, body, RATE_HEADERS)])
    @configuration.transport = transport

    post = RecordingStudio::X.post("55", configuration: @configuration)

    assert_includes calls.first[:url], "/2/tweets/55?"
    assert_equal "https://x.com/i/web/status/55", post.url
    assert_nil post.author
    assert_equal Time.iso8601("2026-01-02T03:04:05Z"), post.created_at
  end

  def test_user_lookup_by_username_and_by_id
    body = {
      "data" => {
        "id" => "2244994945",
        "username" => "XDevelopers",
        "name" => "Developers",
        "description" => "Official",
        "profile_image_url" => "https://example.test/a.png",
        "url" => "https://developer.x.com"
      }
    }
    transport, calls = scripted([json_result(200, body), json_result(200, body)])
    @configuration.transport = transport

    by_name = RecordingStudio::X.user(username: "XDevelopers", configuration: @configuration)
    by_id = RecordingStudio::X.user(id: "2244994945", configuration: @configuration)

    assert_includes calls[0][:url], "/2/users/by/username/XDevelopers?"
    assert_includes calls[1][:url], "/2/users/2244994945?"
    assert_equal "https://x.com/XDevelopers", by_name.url
    assert_equal "https://developer.x.com", by_name.raw["url"]
    assert_equal "2244994945", by_id.id
    assert_equal "Official", by_id.description
  end

  def test_user_lookup_rejects_both_identifiers
    @configuration.transport = ->(*) { raise "called X" }

    error = assert_raises(RecordingStudio::X::InvalidRequestError) do
      RecordingStudio::X.user(id: "1", username: "a", configuration: @configuration)
    end

    assert_equal "Pass a user id or a username, not both", error.message
  end

  def test_user_posts_page_uses_pagination_token_and_exclude
    body = {
      "data" => [{ "id" => "9", "text" => "A post", "author_id" => "7" }],
      "includes" => { "users" => [{ "id" => "7", "username" => "ada", "name" => "Ada" }] },
      "meta" => { "next_token" => "page-2" }
    }
    transport, calls = scripted([json_result(200, body, RATE_HEADERS)])
    @configuration.transport = transport

    page = RecordingStudio::X.user_posts(
      "7", cursor: "page-1", exclude: %w[replies retweets], configuration: @configuration
    )

    assert_includes calls.first[:url], "/2/users/7/tweets?"
    assert_includes calls.first[:url], "pagination_token=page-1"
    assert_includes calls.first[:url], "exclude=replies%2Cretweets"
    assert_equal "ada", page.items.first.author.username
    assert_equal "page-2", page.next_cursor
  end

  def test_application_bearer_is_exchanged_from_consumer_credentials
    @configuration.bearer_token = nil
    @configuration.consumer_key = "consumer-key"
    @configuration.consumer_secret = "consumer-secret"
    token = json_result(200, { "token_type" => "bearer", "access_token" => "exchanged-bearer" })
    search = search_response
    transport, calls = scripted([token, search])
    @configuration.transport = transport

    page = RecordingStudio::X.search(query: "hello", configuration: @configuration)

    assert_equal "POST", calls.first[:method]
    assert_includes calls.first[:url], "/oauth2/token"
    assert_equal "grant_type=client_credentials", calls.first[:body]
    refute_includes calls.first[:body], "consumer-secret"
    assert_equal "Bearer exchanged-bearer", calls.last[:headers]["Authorization"]
    assert_equal "1001", page.items.first.id
    assert_equal "exchanged-bearer", @configuration.application_bearer(transport)
    assert_equal 2, calls.length
  end

  def test_oauth1_user_context_signs_the_request_and_hides_the_secret
    @configuration.bearer_token = nil
    credentials = RecordingStudio::X::Credentials.oauth1(
      consumer_key: "ck", consumer_secret: "consumer-secret",
      access_token: "user-token", access_token_secret: "user-secret"
    )
    transport, calls = scripted([json_result(200, { "data" => { "id" => "1", "text" => "signed" } })])
    @configuration.transport = transport

    post = RecordingStudio::X.post("1", credentials: credentials, configuration: @configuration)
    header = calls.first[:headers]["Authorization"]

    assert_equal "signed", post.text
    assert header.start_with?("OAuth ")
    assert_includes header, 'oauth_consumer_key="ck"'
    assert_includes header, 'oauth_token="user-token"'
    refute_includes header, "consumer-secret"
    refute_includes header, "user-secret"
    assert_equal "#<RecordingStudio::X::Credentials mode=oauth1>", credentials.inspect
  end

  def test_connection_hash_selects_oauth2_for_a_user_token
    connection = { "token" => "user-access", "refresh_token" => "user-refresh" }
    transport, calls = scripted([json_result(200, user_body)])
    @configuration.transport = transport

    user = RecordingStudio::X.user(username: "ada", connection: connection, configuration: @configuration)

    assert_equal "ada", user.username
    assert_equal "Bearer user-access", calls.first[:headers]["Authorization"]
  end

  def test_identity_normalizes_the_authenticated_user_and_rejects_application_credentials
    transport, calls = scripted([json_result(200, user_body("confirmed_email" => "ada@example.test"))])
    @configuration.transport = transport
    credentials = RecordingStudio::X::Credentials.oauth2(access_token: "user-access", scopes: ["users.read"])

    identity = RecordingStudio::X.identity(credentials: credentials, configuration: @configuration)

    assert_includes calls.first[:url], "/2/users/me?"
    assert_includes calls.first[:url], "confirmed_email"
    assert_equal :x, identity.provider
    assert_equal "42", identity.uid
    assert_equal "ada", identity.username
    assert_equal "Ada", identity.name
    assert_equal "https://example.test/a.png", identity.image_url
    assert_equal "ada@example.test", identity.email
    assert_equal "x", identity.to_h["provider"]

    error = assert_raises(RecordingStudio::X::AuthenticationError) do
      RecordingStudio::X.identity(configuration: @configuration)
    end
    assert_equal "identity does not accept application credentials", error.message
  end

  def test_missing_record_preserves_provider_metadata
    body = {
      "errors" => [{
        "detail" => "Could not find tweet",
        "type" => "https://api.x.com/2/problems/resource-not-found",
        "status" => 404
      }]
    }
    @configuration.transport = scripted([json_result(200, body)]).first

    error = assert_raises(RecordingStudio::X::NotFoundError) do
      RecordingStudio::X.post("missing", configuration: @configuration)
    end

    assert_equal "Could not find tweet", error.message
    assert_equal 404, error.status
  end

  def test_http_errors_map_status_code_and_rate_limit
    cases = {
      400 => RecordingStudio::X::InvalidRequestError,
      401 => RecordingStudio::X::AuthenticationError,
      403 => RecordingStudio::X::AuthorizationError,
      404 => RecordingStudio::X::NotFoundError,
      429 => RecordingStudio::X::RateLimitError,
      500 => RecordingStudio::X::ApiError
    }

    cases.each do |status, klass|
      body = { "errors" => [{ "message" => "nope", "code" => 88 }] }
      @configuration.transport = scripted([json_result(status, body, RATE_HEADERS)]).first
      error = assert_raises(klass) do
        RecordingStudio::X.post("1", configuration: @configuration)
      end
      assert_equal status, error.status
      assert_equal 88, error.code
      assert_equal 449, error.rate_limit.remaining
      refute_includes error.message, "app-bearer"
    end
  end

  def test_malformed_json_is_an_invalid_response
    result = RecordingStudio::X::HttpResult.new(status: 200, headers: {}, body: "<html>")
    @configuration.transport = scripted([result]).first

    assert_raises(RecordingStudio::X::InvalidResponseError) do
      RecordingStudio::X.post("1", configuration: @configuration)
    end
  end

  def test_socket_errors_become_network_errors_without_the_original_message
    transport = RecordingStudio::X::NetHttpTransport.new
    Net::HTTP.stub(:new, ->(*) { raise SocketError, "secret-host" }) do
      error = assert_raises(RecordingStudio::X::NetworkError) do
        transport.call(method: "GET", url: "https://api.x.com/2/tweets/1", headers: {}, body: nil)
      end
      assert_equal "SocketError", error.message
    end
  end

  def test_oauth1_signature_matches_rfc_5849_example
    params = {
      "b5" => "=%3D",
      "a3" => ["2 q", "a"],
      "c@" => "",
      "a2" => "r b",
      "c2" => "",
      "oauth_consumer_key" => "9djdj82h48djs9d2",
      "oauth_nonce" => "7d8f3e4a",
      "oauth_signature_method" => "HMAC-SHA1",
      "oauth_timestamp" => "137131201",
      "oauth_token" => "kkk9d7dh3k39sjv7",
      "oauth_version" => "1.0"
    }
    signer = RecordingStudio::X::Oauth1Signer
    base = signer.signature_base("POST", "http://example.com/request", params)

    assert_equal expected_rfc_base, base
    assert_equal "OB33pYjWAnf+xtOHN4Gmbdil168=", signer.signature_for(
      "POST", "http://example.com/request", params, "j49sk3j29djd", "dh893hdasih9"
    )
  end

  def test_instrumentation_records_the_call_and_omits_credentials
    @configuration.transport = scripted([search_response]).first
    events = []
    subscription = ActiveSupport::Notifications.subscribe("request.recording_studio_x") do |*, payload|
      events << payload
    end

    RecordingStudio::X.search(query: "birds", configuration: @configuration)

    payload = events.last
    assert_equal :search, payload[:operation]
    assert_equal "/2/tweets/search/recent", payload[:endpoint]
    assert_equal "application", payload[:authentication]
    assert_equal 1, payload[:request_count]
    assert_equal 1, payload[:result_count]
    assert_nil payload[:error]
    assert_equal 450, payload[:rate_limit]["limit"]
    refute_includes payload.inspect, "app-bearer"
  ensure
    ActiveSupport::Notifications.unsubscribe(subscription) if subscription
  end

  private

  def scripted(responses)
    calls = []
    queue = responses.dup
    transport = lambda do |env|
      calls << env
      queue.shift || raise("no scripted response")
    end
    [transport, calls]
  end

  def json_result(status, body, headers = {})
    RecordingStudio::X::HttpResult.new(status: status, headers: headers, body: JSON.generate(body))
  end

  def search_response(extra = {})
    json_result(200, {
      "data" => [{
        "id" => "1001",
        "text" => "Hello",
        "author_id" => "7",
        "created_at" => "2026-09-01T00:00:00Z",
        "public_metrics" => { "like_count" => 2 }
      }],
      "includes" => { "users" => [{ "id" => "7", "username" => "bowerbird", "name" => "Bowerbird" }] },
      "meta" => { "next_token" => "next-1" }
    }.merge(extra), RATE_HEADERS)
  end

  def user_body(extra = {})
    {
      "data" => {
        "id" => "42",
        "username" => "ada",
        "name" => "Ada",
        "profile_image_url" => "https://example.test/a.png"
      }.merge(extra)
    }
  end

  def expected_rfc_base
    "POST&http%3A%2F%2Fexample.com%2Frequest&a2%3Dr%2520b%26a3%3D2%2520q%26a3%3Da%26" \
      "b5%3D%253D%25253D%26c%2540%3D%26c2%3D%26oauth_consumer_key%3D9djdj82h48djs9d2%26" \
      "oauth_nonce%3D7d8f3e4a%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D137131201%26" \
      "oauth_token%3Dkkk9d7dh3k39sjv7%26oauth_version%3D1.0"
  end
end
