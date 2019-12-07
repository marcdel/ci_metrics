defmodule CiMetricsWeb.RepositoryController do
  require Logger
  use CiMetricsWeb, :controller
  alias CiMetrics.GithubProject
  alias CiMetrics.Metrics.TimeUnitMetric
  alias CiMetrics.Project.Repository

  @project Application.get_env(:ci_metrics, :project, GithubProject)

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{
        "repository_name" => repository_name,
        "access_token" => access_token,
        "deployment_strategy" => deployment_strategy
      }) do
    with {:ok, :webhook_created} <- GithubProject.create_webhook(repository_name, access_token),
         {:ok, _repository} <-
           GithubProject.create_repository(repository_name, deployment_strategy) do
      conn
      |> put_flash(:info, "Repository set up successfully.")
      |> render("new.html")
    else
      {:error, error} ->
        Logger.error(inspect(error))
        error_message = error_to_user_message(error)

        conn
        |> put_flash(:error, error_message)
        |> render("new.html")
    end
  end

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

  defp error_to_user_message(:webhook_exists),
    do: "Oops! This repository already has a webhook from us."

  defp error_to_user_message(:repository_not_found), do: "Oops! We couldn't find that repository."

  defp error_to_user_message(:invalid_credentials),
    do: "Oops! The access token you provided doesn't seem to be working."

  defp error_to_user_message(:webhook_error),
    do: "Oops! We had some trouble creating a webhook for your repository. Please try again."

  defp error_to_user_message(_),
    do: "Oops! We had some trouble setting up your repository. Please try again."
end
