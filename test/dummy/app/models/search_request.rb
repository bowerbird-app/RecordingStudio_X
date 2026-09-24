# frozen_string_literal: true

class SearchRequest
  RECENT_DAYS = 7
  EARLIEST = Date.new(2006, 3, 21)
  SORTS = {
    "recency" => "Newest",
    "relevancy" => "Best match"
  }.freeze

  attr_reader :query, :from, :to, :sort, :cursor, :error

  def self.from_params(params)
    new(
      query: params[:q],
      from: params[:from],
      to: params[:to],
      sort: params[:sort],
      cursor: params[:cursor]
    )
  end

  def initialize(query:, from: nil, to: nil, sort: nil, cursor: nil)
    @query = query.to_s.strip
    @from = blank_to_nil(from)
    @to = blank_to_nil(to)
    @sort = blank_to_nil(sort)
    @cursor = blank_to_nil(cursor)
    @error = nil
    read_filters
  end

  def sorts
    SORTS.map { |value, label| [ label, value ] }
  end

  def sort_value
    SORTS.key?(sort) ? sort : "recency"
  end

  def earliest_date
    EARLIEST
  end

  def latest_date
    Date.current
  end

  def arguments
    {
      query: query,
      max_results: 10,
      cursor: cursor,
      start_time: start_time,
      end_time: usable_end_time,
      sort_order: (sort == "relevancy" ? "relevancy" : nil),
      archive: (true if archive?)
    }.compact
  end

  def page_params(next_cursor)
    { q: query, cursor: next_cursor, from: from, to: to, sort: sort }.compact_blank
  end

  private

  def read_filters
    @from_date = read_date(from)
    @to_date = read_date(to)
    return if error

    check_order
    check_bounds
    check_sort
  end

  def read_date(value)
    return if value.nil?
    return invalid_date unless value.match?(/\A\d{4}-\d{2}-\d{2}\z/)

    Date.iso8601(value)
  rescue Date::Error
    invalid_date
  end

  def invalid_date
    @error = "Those dates are not real."
    nil
  end

  def check_order
    return if from_date.nil? || to_date.nil? || from_date <= to_date

    @error = "The start date is after the end date."
  end

  def check_bounds
    return if error

    [ from_date, to_date ].compact.each do |date|
      if date > latest_date
        @error = "Those dates are still ahead."
        break
      end

      next if date >= earliest_date

      @error = "X starts on 21 March 2006."
      break
    end
  end

  def archive?
    return false if error

    [ from_date, to_date ].compact.any? { |date| date < Date.current - (RECENT_DAYS - 1) }
  end

  def check_sort
    return if error || sort.nil? || SORTS.key?(sort)

    @error = "Pick newest or best match."
  end

  def start_time
    return if from_date.nil?

    from_date.to_time(:utc).iso8601
  end

  def usable_end_time
    finish = end_time
    return if finish.nil?
    return if start_time && finish <= start_time

    finish
  end

  def end_time
    return if to_date.nil?
    return (Time.current.utc - 30.seconds).iso8601 if to_date >= Date.current

    (to_date + 1).to_time(:utc).iso8601
  end

  def from_date
    @from_date
  end

  def to_date
    @to_date
  end

  def blank_to_nil(value)
    text = value.to_s.strip
    text.empty? ? nil : text
  end
end
