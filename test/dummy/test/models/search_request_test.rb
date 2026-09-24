# frozen_string_literal: true

require "test_helper"

class SearchRequestTest < ActiveSupport::TestCase
  test "a reversed range is rejected" do
    request = SearchRequest.new(query: "birds", from: "2026-09-22", to: "2026-09-20")

    assert_equal "The start date is after the end date.", request.error
  end

  test "an unknown sort is rejected" do
    request = SearchRequest.new(query: "birds", sort: "popular")

    assert_equal "Pick newest or best match.", request.error
  end

  test "newest is the default and is not sent to X" do
    request = SearchRequest.new(query: "birds")

    assert_nil request.error
    assert_equal "recency", request.sort_value
    assert_nil request.arguments[:sort_order]
  end
end
