defmodule Domain.OpenTimeCalculator do
  @moduledoc """
  Calculate pull requests open-time.
  """

  @type pr :: %{created_at: String.t()}

  @doc """
  Returns the average number of days PRs have been opened until today.
  """
  @spec calculate(today :: (() -> String.t()), prs :: (() -> [pr])) :: non_neg_integer
  def calculate(today, prs) do
    prs_open_times_until(today.(), prs.())
    |> average
  end

  @spec prs_open_times_until(today :: String.t(), prs :: [pr]) :: [non_neg_integer]
  defp prs_open_times_until(today, prs) do
    prs
    |> Enum.map(fn pr -> pr.created_at end)
    |> Enum.flat_map(fn created_at ->
      case days_opened(today, created_at) do
        {:ok, days_opened} -> [days_opened]
        {:error, _} -> []
      end
    end)
  end

  @spec average(values :: [number]) :: [integer]
  defp average(values) do
    (Enum.sum(values) / Enum.count(values))
    |> round
  end

  @doc """
  Returns the number of days opened until given date.

  ## Examples

      iex> Domain.OpenTimeCalculator.days_opened "2011-01-13T00:00:00Z", "2011-01-10T00:00:00Z"
      {:ok, 3}

      iex> Domain.OpenTimeCalculator.days_opened "2011-02-01T00:00:00Z", "2011-01-01T00:00:00Z"
      {:ok, 31}

      iex> Domain.OpenTimeCalculator.days_opened "2011-01-01T00:00:00Z", "2010-06-01T00:00:00Z"
      {:ok, 214}

      iex> Domain.OpenTimeCalculator.days_opened "2011-01-10T00:00:00Z", "2011-01-13T00:00:00Z"
      {:error, :created_date_in_the_future}
  """
  @spec days_opened(today :: String.t(), created_date :: String.t()) ::
          {:ok, non_neg_integer} | {:error, atom}
  def days_opened(today, created_date) do
    case diff_in_days(today, created_date) do
      {:ok, diff_in_days} when diff_in_days >= 0 ->
        {:ok, diff_in_days}

      {:ok, _diff_in_days} ->
        {:error, :created_date_in_the_future}

      err ->
        err
    end
  end

  @spec diff_in_days(String.t(), String.t()) :: {:ok, integer} | {:error, atom}
  defp diff_in_days(date_1, date_2) do
    with {:ok, date_1_iso8601, _} <- DateTime.from_iso8601(date_1),
         {:ok, date_2_iso8601, _} <- DateTime.from_iso8601(date_2) do
      diff_in_seconds = DateTime.diff(date_1_iso8601, date_2_iso8601, :second)
      seconds_per_day = 1 * 60 * 60 * 24
      diff_in_days = trunc(diff_in_seconds / seconds_per_day)

      {:ok, diff_in_days}
    end
  end
end
