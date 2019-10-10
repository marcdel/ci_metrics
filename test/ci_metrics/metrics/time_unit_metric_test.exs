defmodule CiMetrics.Metrics.TimeUnitMetricTest do
  use ExUnit.Case, async: true

  alias CiMetrics.Metrics.TimeUnitMetric

  test "to_string/1" do
    metric =
      0
      |> TimeUnitMetric.new()
      |> TimeUnitMetric.to_string()

    assert metric == "No data for this metric yet"

    metric =
      60
      |> TimeUnitMetric.new()
      |> TimeUnitMetric.to_string()

    assert metric == "1 minute"

    metric =
      150
      |> TimeUnitMetric.new()
      |> TimeUnitMetric.to_string()

    assert metric == "2 minutes, 30 seconds"

    metric =
      7259
      |> TimeUnitMetric.new()
      |> TimeUnitMetric.to_string()

    assert metric == "2 hours, 59 seconds"

    metric =
      7141
      |> TimeUnitMetric.new()
      |> TimeUnitMetric.to_string()

    assert metric == "1 hour, 59 minutes, 1 second"

    metric =
      86_400
      |> TimeUnitMetric.new()
      |> TimeUnitMetric.to_string()

    assert metric == "1 day"

    metric =
      6_000_000
      |> TimeUnitMetric.new()
      |> TimeUnitMetric.to_string()

    assert metric == "9 weeks, 6 days, 10 hours, 40 minutes"
  end
end
