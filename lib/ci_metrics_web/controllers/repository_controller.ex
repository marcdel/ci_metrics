defmodule CiMetricsWeb.RepositoryController do
  use CiMetricsWeb, :controller
  alias CiMetrics.GithubProject
  alias CiMetrics.Project.Repository

  @project Application.get_env(:ci_metrics, :project, GithubProject)

  def show(conn, params) do
    {average_lead_time, :minutes} = @project.calculate_lead_time(params["id"])
    %{owner: owner, name: name} = Repository.get(params["id"])

    repo = %{owner: owner, name: name, average_lead_time: average_lead_time}
    render(conn, "show.html", repository: repo)
  end
end
