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

  describe "in_minutes/1" do
    test "handles partial minutes" do
      assert TimeUnitMetric.in_minutes(%TimeUnitMetric{
               days: 0,
               hours: 0,
               minutes: 0,
               seconds: 30,
               weeks: 0
             }) == 0.5

      assert TimeUnitMetric.in_minutes(%TimeUnitMetric{
               days: 0,
               hours: 0,
               minutes: 1,
               seconds: 45,
               weeks: 0
             }) == 1.75

      assert TimeUnitMetric.in_minutes(%TimeUnitMetric{
               days: 0,
               hours: 0,
               minutes: 2,
               seconds: 27,
               weeks: 0
             }) == 2.45
    end

    test "handles weeks, days, and hours" do
      assert TimeUnitMetric.in_minutes(%TimeUnitMetric{
               days: 0,
               hours: 0,
               minutes: 0,
               seconds: 0,
               weeks: 1
             }) == 10_080

      assert TimeUnitMetric.in_minutes(%TimeUnitMetric{
               days: 2,
               hours: 0,
               minutes: 0,
               seconds: 0,
               weeks: 0
             }) == 2880

      assert TimeUnitMetric.in_minutes(%TimeUnitMetric{
               days: 0,
               hours: 3,
               minutes: 0,
               seconds: 0,
               weeks: 0
             }) == 180
    end
  end

  describe "in_hours/1" do
    test "handles partial hours" do
      assert TimeUnitMetric.in_hours(%TimeUnitMetric{
               days: 0,
               hours: 0,
               minutes: 30,
               seconds: 0,
               weeks: 0
             }) == 0.5

      assert TimeUnitMetric.in_hours(%TimeUnitMetric{
               days: 0,
               hours: 1,
               minutes: 45,
               seconds: 0,
               weeks: 0
             }) == 1.75

      assert TimeUnitMetric.in_hours(%TimeUnitMetric{
               days: 0,
               hours: 2,
               minutes: 27,
               seconds: 0,
               weeks: 0
             }) == 2.45
    end

    test "handles weeks, and days" do
      assert TimeUnitMetric.in_hours(%TimeUnitMetric{
               days: 0,
               hours: 0,
               minutes: 0,
               seconds: 0,
               weeks: 1
             }) == 168

      assert TimeUnitMetric.in_hours(%TimeUnitMetric{
               days: 2,
               hours: 0,
               minutes: 0,
               seconds: 0,
               weeks: 0
             }) == 48
    end
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
