# frozen_string_literal: true

require "test_helper"

class XApiEndpointsTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.find_or_create_by!(email: "x-api-owner@example.com") do |account|
      account.password = "Password123!"
      account.password_confirmation = "Password123!"
    end
    @workspace = Workspace.create!(name: "X API #{SecureRandom.hex(4)}")
    @root = RecordingStudio.root_recording_for(@workspace)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: @root, actor: @owner)
    raise result.error if result.failure?
    Current.actor = @owner

    @configuration = RecordingStudio::X.configuration
    @bearer = @configuration.bearer_token
    @transport = @configuration.transport
    @configuration.bearer_token = "test-bearer"
  end

  teardown do
    Current.actor = nil
    @configuration.bearer_token = @bearer
    @configuration.transport = @transport
  end

  test "x_search returns 200 with the X HTTP stubbed through configuration.transport" do
    @configuration.transport = lambda do |_env|
      json_result(200, search_body)
    end

    get "/recording_studio_api/api/v1/x/search",
        params: { query: "BowerBird" },
        headers: bearer_headers(issue_token.fetch(:token))

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal "Hello from the search", payload.fetch("items").first.fetch("text")
    assert_equal "next-page", payload.fetch("next_cursor")
  end

  test "x_get_post returns 200 for a stubbed post" do
    @configuration.transport = lambda do |_env|
      json_result(200, post_body)
    end

    get "/recording_studio_api/api/v1/x/posts/9",
        headers: bearer_headers(issue_token.fetch(:token))

    assert_response :success
    assert_equal "from api", JSON.parse(response.body).fetch("text")
  end

  test "x_get_user returns 200 for a stubbed username lookup" do
    @configuration.transport = lambda do |_env|
      json_result(200, user_body)
    end

    get "/recording_studio_api/api/v1/x/users",
        params: { username: "ada" },
        headers: bearer_headers(issue_token.fetch(:token))

    assert_response :success
    assert_equal "ada", JSON.parse(response.body).fetch("username")
  end

  test "x_get_user_posts returns 200 for a stubbed user timeline" do
    @configuration.transport = lambda do |_env|
      json_result(200, search_body)
    end

    get "/recording_studio_api/api/v1/x/users/7/posts",
        params: { max_results: 5 },
        headers: bearer_headers(issue_token.fetch(:token))

    assert_response :success
    assert_equal "Hello from the search", JSON.parse(response.body).fetch("items").first.fetch("text")
  end

  test "x_search returns 401 without a token" do
    get "/recording_studio_api/api/v1/x/search", params: { query: "BowerBird" }

    assert_response :unauthorized
  end

  test "x_search returns 403 when the actor cannot view the root" do
    issued = issue_token
    RecordingStudio::Access.where(id: issued.fetch(:access_recording).recordable_id).update_all(role: "")
    refute RecordingStudioAccessible.authorized?(
      actor: issued.fetch(:access_recording).recordable.reload.actor,
      recording: @root,
      role: :view
    )

    get "/recording_studio_api/api/v1/x/search",
        params: { query: "BowerBird" },
        headers: bearer_headers(issued.fetch(:token))

    assert_response :forbidden
  end

  test "x_search returns 422 when query is missing" do
    get "/recording_studio_api/api/v1/x/search",
        headers: bearer_headers(issue_token.fetch(:token))

    assert_response :unprocessable_entity
    assert_equal "invalid_input", JSON.parse(response.body).dig("error", "code")
  end

  private

  def bearer_headers(token)
    { "Authorization" => "Bearer #{token}" }
  end

  def issue_token
    access_recording = RecordingStudioAccessible.access_recordings_for_actor(
      recording: @root,
      actor: @owner
    ).first
    raise "missing access recording" if access_recording.blank?

    provision = RecordingStudioAccessible::AccessCreationContext.allow do
      RecordingStudioApi::Services::ProvisionApiClient.call(
        access_point_recording: @root,
        manager_actor: @owner,
        role: access_recording.recordable.role,
        name: "X API HTTP client #{SecureRandom.hex(4)}"
      )
    end
    raise provision.error unless provision.success?

    token_result = RecordingStudioApi::Services::IssueOauthAccessToken.call(
      grant_type: "client_credentials",
      client_id: provision.value.fetch(:credential).oauth_client_id,
      client_secret: provision.value.fetch(:token)
    )
    raise token_result.error unless token_result.success?

    {
      token: token_result.value.fetch(:access_token),
      access_recording: provision.value.fetch(:access_recording)
    }
  end

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

  def post_body
    {
      "data" => { "id" => "9", "text" => "from api", "author_id" => "7" },
      "includes" => { "users" => [{ "id" => "7", "username" => "ada", "name" => "Ada" }] }
    }
  end

  def user_body
    { "data" => { "id" => "7", "username" => "ada", "name" => "Ada" } }
  end
end
