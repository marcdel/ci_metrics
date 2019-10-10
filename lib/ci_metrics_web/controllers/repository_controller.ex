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

    %{owner: owner, name: name} = Repository.get(params["id"])

    repo = %{owner: owner, name: name, average_lead_time: lead_time}
    render(conn, "show.html", repository: repo)
  end
end
