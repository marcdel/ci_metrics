defmodule CiMetricsWeb.RepositoryController do
  use CiMetricsWeb, :controller
  alias CiMetrics.GithubProject
  alias CiMetrics.Metrics.TimeUnitMetric
  alias CiMetrics.Project.Repository

  @project Application.get_env(:ci_metrics, :project, GithubProject)

  def show(conn, params) do
    lead_time =
      params["id"]
      |> @project.calculate_lead_time()
      |> TimeUnitMetric.to_string()

    lead_time_snapshots = @project.daily_lead_time_snapshots(params["id"])

    lead_times_in_days =
      lead_time_snapshots
      |> Enum.map(&TimeUnitMetric.new(&1.average_lead_time))
      |> Enum.map(&TimeUnitMetric.in_hours(&1))
      |> Enum.map(&Float.to_string(&1))

    lead_time_dates =
      lead_time_snapshots
      |> Enum.map(fn %{inserted_at: d} -> "#{d.month}/#{d.day}/#{d.year}" end)

    %{owner: owner, name: name} = Repository.get(params["id"])

    repo = %{
      owner: owner,
      name: name,
      average_lead_time: lead_time,
      dates: lead_time_dates,
      lead_times: lead_times_in_days
    }

    render(conn, "show.html", repository: repo)
  end
end
