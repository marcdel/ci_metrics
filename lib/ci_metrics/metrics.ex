defmodule CiMetrics.Metrics do
  alias CiMetrics.GithubProject
  alias CiMetrics.Project.Repository
  alias CiMetrics.Metrics.MetricSnapshot
  alias CiMetrics.Metrics.TimeUnitMetric
  alias CiMetrics.Repo

  @project Application.get_env(:ci_metrics, :project, GithubProject)

  def save_average_lead_time_snapshots do
    Repository.get_all()
    |> Parallel.map(&calculate_snapshot(&1))
    |> Parallel.map(&save_metric_snapshot(&1))
  end

  defp calculate_snapshot(%{id: id}) do
    lead_time_in_seconds =
      id
      |> @project.calculate_lead_time()
      |> TimeUnitMetric.in_seconds()

    %{repository_id: id, average_lead_time: lead_time_in_seconds}
  end

  defp save_metric_snapshot(params) do
    {:ok, snapshot} =
      %MetricSnapshot{}
      |> MetricSnapshot.changeset(params)
      |> Repo.insert()

    snapshot
  end
end
