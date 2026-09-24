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

  test "dates inside the last 7 days stay on recent search" do
    travel_to Time.utc(2026, 9, 24, 15, 0, 0) do
      request = SearchRequest.new(query: "birds", from: "2026-09-18", to: "2026-09-24")

      assert_nil request.error
      refute request.arguments.key?(:archive)
    end
  end

  test "an older date uses the archive and a date before the first post is rejected" do
    travel_to Time.utc(2026, 9, 24, 15, 0, 0) do
      older = SearchRequest.new(query: "birds", from: "2026-09-17")
      too_old = SearchRequest.new(query: "birds", from: "2006-03-20")
      ahead = SearchRequest.new(query: "birds", to: "2026-09-25")

      assert older.arguments[:archive]
      assert_equal "2026-09-17T00:00:00Z", older.arguments[:start_time]
      assert_equal "X starts on 21 March 2006.", too_old.error
      assert_equal "Those dates are still ahead.", ahead.error
    end
  end

  test "newest is the default and is not sent to X" do
    request = SearchRequest.new(query: "birds")

    assert_nil request.error
    assert_equal "recency", request.sort_value
    assert_nil request.arguments[:sort_order]
  end
end
