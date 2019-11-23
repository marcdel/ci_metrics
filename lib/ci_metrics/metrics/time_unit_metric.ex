defmodule CiMetrics.Metrics.TimeUnitMetric do
  alias CiMetrics.Metrics.TimeUnitMetric

  defstruct weeks: 0, days: 0, hours: 0, minutes: 0, seconds: 0

  def new(seconds) do
    {_, [s, m, h, d, w]} =
      Enum.reduce(divisors(), {seconds, []}, fn divisor, {n, acc} ->
        {rem(n, divisor), [div(n, divisor) | acc]}
      end)

    %TimeUnitMetric{
      weeks: w,
      days: d,
      hours: h,
      minutes: m,
      seconds: s
    }
  end

  def to_string(%TimeUnitMetric{} = metric) do
    [
      pluralize(metric.weeks, "week"),
      pluralize(metric.days, "day"),
      pluralize(metric.hours, "hour"),
      pluralize(metric.minutes, "minute"),
      pluralize(metric.seconds, "second")
    ]
    |> Enum.reject(fn str -> String.starts_with?(str, "0") end)
    |> Enum.join(", ")
    |> or_default_message()
  end

  def in_seconds(%TimeUnitMetric{weeks: w, days: d, hours: h, minutes: m, seconds: s}) do
    [week, day, hour, minute, second] = divisors()

    w * week + day * d + hour * h + minute * m + second * s
  end

  def in_minutes(%TimeUnitMetric{
        weeks: weeks,
        days: days,
        hours: hours,
        minutes: minutes,
        seconds: seconds
      }) do
    weeks * 10_080 + days * 1440 + hours * 60 + minutes + Float.round(seconds / 60, 2)
  end

  def in_hours(%TimeUnitMetric{weeks: weeks, days: days, hours: hours, minutes: minutes}) do
    weeks * 168 + days * 24 + hours + Float.round(minutes / 60, 2)
  end

  def in_days(%TimeUnitMetric{weeks: weeks, days: days, hours: hours}) do
    weeks * 7 + days + Float.round(hours / 24, 2)
  end

  defp divisors() do
    minute = 60
    hour = minute * 60
    day = hour * 24
    week = day * 7

    [week, day, hour, minute, 1]
  end

  defp pluralize(value, unit) when value == 1 do
    "#{value} #{unit}"
  end

  defp pluralize(value, unit) when value > 1 or value == 0 do
    "#{value} #{unit}s"
  end

  defp or_default_message(""), do: "No data for this metric yet"
  defp or_default_message(message), do: message
end
