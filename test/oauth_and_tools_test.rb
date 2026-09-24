# frozen_string_literal: true

require "test_helper"
require "base64"
require "digest"

class OauthAndToolsTest < Minitest::Test
  def setup
    @configuration = RecordingStudio::X::Configuration.new
    names = %i[bearer_token consumer_key consumer_secret access_token access_token_secret client_id client_secret]
    names.each do |name|
      @configuration.public_send("#{name}=", nil)
    end
    @configuration.client_id = "client-id"
    @configuration.client_secret = "client-secret"
  end

  def test_pkce_challenge_is_s256_of_the_verifier
    pair = RecordingStudio::X::Oauth.pkce
    expected = Base64.urlsafe_encode64(Digest::SHA256.digest(pair[:verifier]), padding: false)

    assert_equal 64, pair[:verifier].length
    assert_equal "S256", pair[:method]
    assert_equal expected, pair[:challenge]
  end

  def test_authorize_url_carries_pkce_and_scopes_without_the_client_secret
    url = RecordingStudio::X.authorize_url(
      redirect_uri: "https://app.example/callback",
      state: "state-1",
      code_challenge: "challenge",
      configuration: @configuration
    )

    assert url.start_with?("https://x.com/i/oauth2/authorize?")
    assert_includes url, "client_id=client-id"
    assert_includes url, "code_challenge=challenge"
    assert_includes url, "code_challenge_method=S256"
    assert_includes url, "scope=tweet.read%20users.read%20offline.access"
    refute_includes url, "client-secret"
  end

  def test_exchange_and_refresh_return_a_token_set_that_hides_secrets
    token_body = {
      "token_type" => "bearer",
      "expires_in" => 7200,
      "access_token" => "access-secret",
      "refresh_token" => "refresh-secret",
      "scope" => "tweet.read users.read offline.access"
    }
    calls = []
    @configuration.transport = lambda do |env|
      calls << env
      RecordingStudio::X::HttpResult.new(status: 200, headers: {}, body: JSON.generate(token_body))
    end

    exchanged = RecordingStudio::X.exchange_code(
      code: "auth-code", redirect_uri: "https://app.example/callback",
      code_verifier: "verifier", configuration: @configuration
    )
    refreshed = RecordingStudio::X.refresh(refresh_token: "refresh-secret", configuration: @configuration)

    assert_equal "access-secret", exchanged.access_token
    assert_equal true, exchanged.to_h["refresh_token_present"]
    refute_includes exchanged.inspect, "access-secret"
    refute_includes exchanged.inspect, "refresh-secret"
    assert_equal "authorization_code", form(calls.first)["grant_type"]
    assert_equal "verifier", form(calls.first)["code_verifier"]
    refute_includes calls.first[:body], "client-secret"
    assert calls.first[:headers]["Authorization"].start_with?("Basic ")
    assert_equal "refresh_token", form(calls.last)["grant_type"]
    assert_equal "refresh-secret", refreshed.refresh_token
  end

  def test_public_client_omits_basic_authorization
    @configuration.client_secret = nil
    calls = []
    @configuration.transport = lambda do |env|
      calls << env
      RecordingStudio::X::HttpResult.new(status: 200, headers: {}, body: JSON.generate("access_token" => "a"))
    end

    RecordingStudio::X.exchange_code(
      code: "auth-code", redirect_uri: "https://app.example/callback",
      code_verifier: "verifier", configuration: @configuration
    )

    refute calls.first[:headers].key?("Authorization")
  end

  def test_authorize_url_requires_a_client_id
    @configuration.client_id = nil

    assert_raises(RecordingStudio::X::ConfigurationError) do
      RecordingStudio::X.authorize_url(
        redirect_uri: "https://app.example/callback", state: "s",
        code_challenge: "c", configuration: @configuration
      )
    end
  end

  def test_provider_contract_names_x_endpoints
    provider = RecordingStudio::X::Oauth.provider

    assert_equal "x", provider["provider"]
    assert_equal "https://x.com/i/oauth2/authorize", provider["authorize_url"]
    assert_equal "https://api.x.com/2/oauth2/token", provider["token_url"]
    assert_equal "GET /2/users/me", provider["identity_endpoint"]
    assert_equal "S256", provider["pkce"]
    assert_includes provider["sign_in_scopes"], "offline.access"
    assert_includes provider["connect_scopes"], "tweet.write"
  end

  def test_capabilities_distinguish_read_application_calls_from_user_writes
    search = RecordingStudio::X.capability(:search)
    create_post = RecordingStudio::X.capability(:create_post)

    assert_equal :read, search.access
    assert_equal false, search.side_effects?
    assert_equal true, search.allows?(:application)
    assert_equal true, search.allows?(:oauth2)
    assert_equal true, search.implemented
    assert_equal :write, create_post.access
    assert_equal true, create_post.side_effects?
    assert_equal false, create_post.allows?(:application)
    assert_equal true, create_post.allows?(:oauth1)
    assert_equal false, create_post.implemented
    assert_includes create_post.scopes, "tweet.write"
    assert_equal false, RecordingStudio::X.capability(:identity).allows?(:application)
  end

  def test_ai_tools_are_read_only_and_return_plain_results
    @configuration.bearer_token = "app-bearer"
    @configuration.transport = lambda do |_env|
      RecordingStudio::X::HttpResult.new(
        status: 200,
        headers: {},
        body: JSON.generate("data" => { "id" => "9", "text" => "from tool" })
      )
    end
    RecordingStudio::X.instance_variable_set(:@configuration, @configuration)
    tool = RecordingStudio::X::AiTools.catalog.find { |entry| entry[:key] == :x_get_post }

    result = tool[:registration][:executor].call({ "id" => "9" }, nil)

    assert_equal "from tool", result["text"]
    assert_equal true, tool[:registration][:read_only]
    assert_equal false, tool[:registration][:destructive]
    assert_equal false, tool[:side_effects]
    assert_equal :read, tool[:access]
    assert_includes tool[:authentication], :application
    keys = RecordingStudio::X::AiTools.catalog.map { |entry| entry[:key] }
    assert_equal %i[x_search x_get_post x_get_user x_get_user_posts], keys
  ensure
    RecordingStudioXTest.blank_configuration!
  end

  def test_ai_registration_is_optional
    hide_recording_studio_ai
    assert_nil RecordingStudio::X::AiTools.register!
  end

  def test_ai_registration_uses_the_host_registry
    recorder = Class.new do
      attr_reader :calls

      def initialize
        @calls = []
      end

      def register(**kwargs)
        @calls << kwargs
      end
    end.new
    stub = Module.new do
      define_singleton_method(:tools) { recorder }
    end
    Object.const_set(:RecordingStudioAI, stub)

    RecordingStudio::X::AiTools.register!

    keys = recorder.calls.map { |call| call[:key] }
    assert_equal %i[x_search x_get_post x_get_user x_get_user_posts], keys
    read_only = recorder.calls.map { |call| call[:read_only] }
    assert_equal [true, true, true, true], read_only
    assert(recorder.calls.all? { |call| call[:override] == true })
  ensure
    Object.send(:remove_const, :RecordingStudioAI) if defined?(::RecordingStudioAI)
  end

  def test_diagnostics_report_flags_without_secret_values
    @configuration.bearer_token = "super-secret-token"
    @configuration.consumer_key = "ck"
    @configuration.consumer_secret = "cs"
    @configuration.client_id = nil
    @configuration.client_secret = nil

    report = RecordingStudio::X::Diagnostics.report(configuration: @configuration)

    assert_equal "configured", report["application_bearer_token"]
    assert_equal "configured", report["oauth1_app_credentials"]
    assert_equal "missing", report["oauth1_user_credentials"]
    assert_equal "missing", report["oauth2_client_credentials"]
    refute_includes report.inspect, "super-secret-token"
  end

  def test_diagnostics_probe_reports_success_or_the_error_class
    @configuration.bearer_token = "app-bearer"
    @configuration.transport = lambda do |_env|
      RecordingStudio::X::HttpResult.new(
        status: 200, headers: {},
        body: JSON.generate("data" => { "id" => "1", "username" => "XDevelopers", "name" => "Developers" })
      )
    end

    ok = RecordingStudio::X.diagnose(probe: true, configuration: @configuration)

    assert_equal true, ok["probe"]["ok"]
    assert_equal "application", ok["probe"]["authentication"]
    assert_equal "XDevelopers", ok["probe"]["username"]

    @configuration.transport = lambda do |_env|
      RecordingStudio::X::HttpResult.new(
        status: 401, headers: {},
        body: JSON.generate("errors" => [{ "message" => "token rejected", "code" => 89 }])
      )
    end
    failed = RecordingStudio::X.diagnose(probe: true, configuration: @configuration)

    assert_equal false, failed["probe"]["ok"]
    assert_equal "RecordingStudio::X::AuthenticationError", failed["probe"]["error"]
    assert_equal 401, failed["probe"]["status"]
    refute_includes failed.inspect, "token rejected"
    refute_includes failed.inspect, "app-bearer"
  end

  def test_credentials_from_connection_duck_type
    credentials = RecordingStudio::X::Credentials.oauth1(
      consumer_key: "ck", consumer_secret: "cs", access_token: "at", access_token_secret: "ats"
    )
    connection = Struct.new(:to_x_credentials).new(credentials)

    resolved = RecordingStudio::X::Credentials.from_connection(connection, configuration: @configuration)

    assert_equal :oauth1, resolved.mode
    assert_equal "at", resolved.access_token
  end

  private

  def form(env)
    env[:body].split("&").to_h { |pair| pair.split("=", 2) }
  end

  def hide_recording_studio_ai
    Object.send(:remove_const, :RecordingStudioAI) if defined?(::RecordingStudioAI)
  end
end
