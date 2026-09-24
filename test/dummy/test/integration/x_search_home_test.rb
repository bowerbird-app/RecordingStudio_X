require "test_helper"
require "devise/test/integration_helpers"

class XSearchHomeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.find_or_create_by!(email: "x-search-home@example.com") do |record|
      record.password = "Password123!"
      record.password_confirmation = "Password123!"
    end
    sign_in @user
    @configuration = RecordingStudio::X.configuration
    @bearer = @configuration.bearer_token
    @transport = @configuration.transport
    @configuration.bearer_token = "test-bearer"
  end

  teardown do
    @configuration.bearer_token = @bearer
    @configuration.transport = @transport
  end

  test "home shows a search field and does not call X yet" do
    @configuration.transport = ->(*) { flunk "search should wait for a query" }

    get root_path

    assert_response :success
    assert_select "input[name=q]"
    assert_select "form[action='/'] button[name=button]", count: 0
    assert_includes response.body, "Search X"
    assert_includes response.body, "Recent posts from the last 7 days."
  end

  test "home lists posts returned by the X search" do
    calls = []
    @configuration.transport = lambda do |env|
      calls << env
      json_result(200, search_body)
    end

    get root_path, params: { q: "BowerBird" }

    assert_response :success
    assert_includes calls.first[:url], "query=BowerBird"
    assert_includes calls.first[:url], "max_results=10"
    refute_includes calls.first[:url], "next_token"
    assert_includes response.body, "Hello from the search"
    assert_includes response.body, "@ada"
    assert_includes response.body, "More posts"
    assert_includes response.body, "cursor=next-page"
  end

  test "home explains an X refusal without the provider message" do
    @configuration.transport = lambda do |_env|
      json_result(403, "errors" => [{ "detail" => "token super-secret-value" }])
    end

    get root_path, params: { q: "BowerBird" }

    assert_response :success
    assert_includes response.body, "X refused this app"
    refute_includes response.body, "super-secret-value"
    refute_includes response.body, "AuthorizationError"
  end

  private

  def json_result(status, body)
    RecordingStudio::X::HttpResult.new(status: status, headers: {}, body: JSON.generate(body))
  end

  def search_body
    {
      "data" => [{
        "id" => "1001",
        "text" => "Hello from the search",
        "author_id" => "7",
        "created_at" => "2026-09-01T00:00:00Z",
        "public_metrics" => { "like_count" => 3 }
      }],
      "includes" => { "users" => [{ "id" => "7", "username" => "ada", "name" => "Ada" }] },
      "meta" => { "next_token" => "next-page" }
    }
  end
end
