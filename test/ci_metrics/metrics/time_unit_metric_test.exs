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

  test "in_seconds/1" do
    metric =
      0
      |> TimeUnitMetric.new()
      |> TimeUnitMetric.in_seconds()

    assert metric == 0

    metric =
      60
      |> TimeUnitMetric.new()
      |> TimeUnitMetric.in_seconds()

    assert metric == 60

    metric =
      150
      |> TimeUnitMetric.new()
      |> TimeUnitMetric.in_seconds()

    assert metric == 150

    metric =
      7259
      |> TimeUnitMetric.new()
      |> TimeUnitMetric.in_seconds()

    assert metric == 7259

    metric =
      7141
      |> TimeUnitMetric.new()
      |> TimeUnitMetric.in_seconds()

    assert metric == 7141

    metric =
      86_400
      |> TimeUnitMetric.new()
      |> TimeUnitMetric.in_seconds()

    assert metric == 86_400

    metric =
      6_000_000
      |> TimeUnitMetric.new()
      |> TimeUnitMetric.in_seconds()

    assert metric == 6_000_000
  end

  describe "in_days/1" do
    test "returns 0 if less than an hour" do
      assert TimeUnitMetric.in_days(%TimeUnitMetric{
               days: 0,
               hours: 0,
               minutes: 0,
               seconds: 0,
               weeks: 0
             }) == 0

      assert TimeUnitMetric.in_days(%TimeUnitMetric{
               days: 0,
               hours: 0,
               minutes: 20,
               seconds: 50,
               weeks: 0
             }) == 0
    end

    test "handles partial days" do
      assert TimeUnitMetric.in_days(%TimeUnitMetric{
               days: 0,
               hours: 12,
               minutes: 0,
               seconds: 0,
               weeks: 0
             }) == 0.5

      assert TimeUnitMetric.in_days(%TimeUnitMetric{
               days: 1,
               hours: 10,
               minutes: 0,
               seconds: 0,
               weeks: 0
             }) == 1.42

      assert TimeUnitMetric.in_days(%TimeUnitMetric{
               days: 2,
               hours: 20,
               minutes: 0,
               seconds: 0,
               weeks: 0
             }) == 2.83
    end

    test "shows weeks in days" do
      assert TimeUnitMetric.in_days(%TimeUnitMetric{
               days: 0,
               hours: 0,
               minutes: 0,
               seconds: 0,
               weeks: 1
             }) == 7

      assert TimeUnitMetric.in_days(%TimeUnitMetric{
               days: 1,
               hours: 20,
               minutes: 0,
               seconds: 0,
               weeks: 1
             }) == 8.83
    end
  end
end
