defmodule CiMetrics.MetricsTest do
  use CiMetrics.DataCase, async: true
  alias CiMetrics.Metrics
  alias CiMetrics.Metrics.TimeUnitMetric
  alias CiMetrics.Project.Repository

  import Mox
  setup :verify_on_exit!

  test "save_average_lead_time_snapshots/0" do
    {:ok, %{id: repository_id}} = Repository.insert_or_update(%{owner: "owner", name: "repo"})
    expect(MockProject, :calculate_lead_time, fn _ -> TimeUnitMetric.new(7) end)

    [snapshot] = Metrics.save_average_lead_time_snapshots()

    assert snapshot.repository_id == repository_id
    assert snapshot.average_lead_time == 7
  end
end
