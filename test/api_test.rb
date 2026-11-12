# frozen_string_literal: true

require "test_helper"

class ApiTest < Minitest::Test
  def test_register_is_optional_without_recording_studio_api
    refute defined?(RecordingStudioApi)
    assert_nil RecordingStudio::X::Api.register!
  end

  def test_search_handler_returns_a_page_after_view_authorization
    configuration = RecordingStudioXTest.blank_configuration!
    configuration.bearer_token = "app-bearer"
    configuration.transport = lambda do |_env|
      RecordingStudio::X::HttpResult.new(
        status: 200,
        headers: {},
        body: JSON.generate(
          "data" => [{ "id" => "1", "text" => "hello", "author_id" => "7" }],
          "includes" => { "users" => [{ "id" => "7", "username" => "ada", "name" => "Ada" }] },
          "meta" => { "next_token" => "next" }
        )
      )
    end

    result = RecordingStudio::X::Api::Handlers::Search.call(
      context(params: { query: "birds", max_results: 10, cursor: nil })
    )

    assert_equal "hello", result["items"].first["text"]
    assert_equal "next", result["next_cursor"]
  ensure
    RecordingStudioXTest.blank_configuration!
  end

  def test_user_posts_handler_returns_a_page
    configuration = RecordingStudioXTest.blank_configuration!
    configuration.bearer_token = "app-bearer"
    configuration.transport = lambda do |_env|
      RecordingStudio::X::HttpResult.new(
        status: 200,
        headers: {},
        body: JSON.generate(
          "data" => [{ "id" => "2", "text" => "timeline", "author_id" => "7" }],
          "includes" => { "users" => [{ "id" => "7", "username" => "ada", "name" => "Ada" }] }
        )
      )
    end

    result = RecordingStudio::X::Api::Handlers::UserPosts.call(
      context(params: { id: "7", max_results: 5, cursor: nil, exclude: "replies" })
    )

    assert_equal "timeline", result["items"].first["text"]
  ensure
    RecordingStudioXTest.blank_configuration!
  end

  def test_endpoint_catalog_covers_the_four_reads
    names = RecordingStudio::X::Api::ENDPOINTS.map { |endpoint| endpoint.fetch(:name) }

    assert_equal %i[x_search x_get_post x_get_user x_get_user_posts], names
    RecordingStudio::X::Api::ENDPOINTS.each do |endpoint|
      assert_equal false, endpoint.dig(:input_contract, :reject_unknown)
      assert_match(/\AX - /, endpoint.dig(:openapi, :summary))
      assert endpoint.dig(:openapi, :description)
      assert(endpoint.dig(:openapi, :parameters).all? { |parameter| parameter[:description].present? })
    end
  end

  private

  def context(params:)
    grant = Object.new
    def grant.authorize!(recording:, role:)
      raise "missing recording" if recording.nil?
      raise "expected view" unless role == :view
    end

    Struct.new(:access_grant, :root_recording, :params).new(grant, Object.new, params)
  end
end
