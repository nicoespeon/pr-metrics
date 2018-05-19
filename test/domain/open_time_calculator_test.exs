defmodule Domain.OpenTimeCalculatorTest do
  use ExUnit.Case
  doctest Domain.OpenTimeCalculator

  @today "2011-01-10T00:00:00Z"
  @three_days_after "2011-01-13T00:00:00Z"
  @two_days_before "2011-01-08T00:00:00Z"
  @three_days_before "2011-01-07T00:00:00Z"
  @four_days_before "2011-01-06T00:00:00Z"
  @invalid_date "2011-32-00"

  test "returns number of days opened until given date" do
    {:ok, days_opened} = Domain.OpenTimeCalculator.days_opened(@today, @three_days_before)

    assert days_opened == 3
  end

  test "fails if given date is before created date" do
    result = Domain.OpenTimeCalculator.days_opened(@today, @three_days_after)

    assert result == {:error, :created_date_in_the_future}
  end

  test "fails if given date has an invalid format" do
    result = Domain.OpenTimeCalculator.days_opened(@today, @invalid_date)

    assert result == {:error, :invalid_format}
  end

  test "returns average number of days PRs have been opened until given date" do
    today = fn -> @today end

    prs = fn ->
      [
        %{created_at: @two_days_before},
        %{created_at: @three_days_before},
        %{created_at: @four_days_before}
      ]
    end

    avg_open_time = Domain.OpenTimeCalculator.calculate(today, prs)

    assert avg_open_time == 3
  end

  test "omits PRs with an invalid date when calculating open time" do
    today = fn -> @today end

    prs = fn ->
      [
        %{created_at: @two_days_before},
        %{created_at: @three_days_before},
        %{created_at: @invalid_date},
        %{created_at: @four_days_before}
      ]
    end

    avg_open_time = Domain.OpenTimeCalculator.calculate(today, prs)

    assert avg_open_time == 3
  end

  test "rounds the average open time" do
    today = fn -> @today end

    prs = fn ->
      [
        %{created_at: @two_days_before},
        %{created_at: @two_days_before},
        %{created_at: @three_days_before}
      ]
    end

    avg_open_time = Domain.OpenTimeCalculator.calculate(today, prs)

    assert avg_open_time == 2
  end
end
