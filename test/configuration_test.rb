# frozen_string_literal: true

require "test_helper"

class ConfigurationTest < Minitest::Test
  ENV_KEYS = %w[
    x_bearer_token x_consumer_key x_consumer_key_secret x_consumer_secret
    x_access_token x_access_token_secret x_client_id x_client_secret
  ].freeze

  def setup
    @configuration = blank_configuration
  end

  def test_merge_updates_known_attributes
    @configuration.merge!(bearer_token: "abc123", read_timeout: 9, instrumentation_enabled: false)

    assert_equal "abc123", @configuration.bearer_token
    assert_equal 9, @configuration.read_timeout
    assert_equal false, @configuration.instrumentation_enabled
  end

  def test_merge_ignores_unknown_keys
    @configuration.merge!(unknown_key: "ignored", read_timeout: 7)

    refute_respond_to @configuration, :unknown_key
    assert_equal 7, @configuration.read_timeout
  end

  def test_merge_with_non_enumerable_is_noop
    @configuration.merge!(nil)

    assert_nil @configuration.bearer_token
    assert_equal 10, @configuration.read_timeout
    assert_equal true, @configuration.instrumentation_enabled?
  end

  def test_initialize_reads_x_environment_names
    with_env(
      "x_bearer_token" => "bearer-from-env",
      "x_consumer_key" => "ck-from-env",
      "x_consumer_key_secret" => "cs-from-env",
      "x_access_token" => "at-from-env",
      "x_access_token_secret" => "ats-from-env",
      "x_client_id" => "cid-from-env",
      "x_client_secret" => "csec-from-env"
    ) do
      configuration = RecordingStudio::X::Configuration.new

      assert_equal "bearer-from-env", configuration.bearer_token
      assert_equal "ck-from-env", configuration.consumer_key
      assert_equal "cs-from-env", configuration.consumer_secret
      assert_equal "at-from-env", configuration.access_token
      assert_equal "cid-from-env", configuration.client_id
      assert_equal true, configuration.oauth1_user_configured?
      assert_equal true, configuration.oauth2_client_configured?
      assert_equal "configured", configuration.to_h[:application_bearer_token]
      refute_includes configuration.inspect, "bearer-from-env"
      refute_includes configuration.inspect, "cs-from-env"
      refute_includes configuration.to_h.values.map(&:to_s).join, "csec-from-env"
    end
  end

  def test_consumer_secret_falls_back_when_key_secret_is_blank
    with_env(
      "x_consumer_key" => "ck",
      "x_consumer_key_secret" => "",
      "x_consumer_secret" => "legacy-secret"
    ) do
      configuration = RecordingStudio::X::Configuration.new

      assert_equal "legacy-secret", configuration.consumer_secret
      assert_equal true, configuration.oauth1_app_configured?
    end
  end

  def test_default_credentials_prefer_application_over_user_tokens
    @configuration.consumer_key = "ck"
    @configuration.consumer_secret = "cs"
    @configuration.access_token = "user-token"
    @configuration.access_token_secret = "user-secret"

    credentials = @configuration.default_credentials

    assert_equal :application, credentials.mode
    assert_equal "ck", credentials.consumer_key
    assert_nil credentials.access_token
  end

  def test_default_credentials_use_oauth1_user_when_only_user_material_is_incomplete_app
    @configuration.consumer_key = "ck"
    @configuration.consumer_secret = nil

    assert_nil @configuration.default_credentials
  end

  def test_merge_accepts_string_keys
    @configuration.merge!("bearer_token" => "string-key", "read_timeout" => 12)

    assert_equal "string-key", @configuration.bearer_token
    assert_equal 12, @configuration.read_timeout
  end

  def test_to_h_reports_registered_hook_counts
    @configuration.hooks.before_initialize { nil }
    @configuration.hooks.before_initialize { nil }
    @configuration.hooks.after_service { nil }

    result = @configuration.to_h

    assert_equal 2, result.fetch(:hooks_registered).fetch(:before_initialize)
    assert_equal 1, result.fetch(:hooks_registered).fetch(:after_service)
  end

  def test_configure_without_block_is_safe
    RecordingStudio::X.configure

    assert_kind_of RecordingStudio::X::Configuration, RecordingStudio::X.configuration
  end

  def test_changing_consumer_secret_clears_cached_application_bearer
    @configuration.consumer_key = "ck"
    @configuration.consumer_secret = "cs"
    transport, = scripted([json_result(200, { "access_token" => "minted-bearer" })])
    assert_equal "minted-bearer", @configuration.application_bearer(transport)

    @configuration.consumer_secret = "rotated"
    transport2, calls = scripted([json_result(200, { "access_token" => "rotated-bearer" })])

    assert_equal "rotated-bearer", @configuration.application_bearer(transport2)
    assert_equal 1, calls.length
  end

  private

  def blank_configuration
    configuration = RecordingStudio::X::Configuration.new
    ENV_KEYS.each do |key|
      setter = key.delete_prefix("x_")
      setter = "consumer_secret" if setter == "consumer_key_secret"
      configuration.public_send("#{setter}=", nil) if configuration.respond_to?("#{setter}=")
    end
    configuration
  end

  def with_env(values)
    saved = ENV_KEYS.to_h { |key| [key, ENV.fetch(key, nil)] }
    ENV_KEYS.each { |key| ENV.delete(key) }
    values.each { |key, value| ENV[key] = value }
    yield
  ensure
    ENV_KEYS.each do |key|
      saved[key].nil? ? ENV.delete(key) : ENV[key] = saved[key]
    end
  end

  def scripted(responses)
    calls = []
    queue = responses.dup
    transport = lambda do |env|
      calls << env
      queue.shift
    end
    [transport, calls]
  end

  def json_result(status, body, headers = {})
    RecordingStudio::X::HttpResult.new(status: status, headers: headers, body: JSON.generate(body))
  end
end
