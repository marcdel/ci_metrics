defmodule CiMetrics.GithubProject do
  @behaviour CiMetrics.Project

  require Logger
  import Ecto.Query

  alias CiMetrics.{GithubClient, Repo}
  alias CiMetrics.Events.{Deployment, DeploymentStatus, Event, EventProcessor, Push}
  alias CiMetrics.Metrics.{LeadTime, TimeUnitMetric}
  alias CiMetrics.Project.Repository

  @impl CiMetrics.Project
  def calculate_lead_time(repository_id), do: LeadTime.calculate(repository_id)

  def create_webhook(repository_name, access_token) do
    GithubClient.create_webhook(%{
      repository_name: repository_name,
      access_token: access_token,
      callback_url: Application.get_env(:ci_metrics, :webhook_callback_url),
      events: ["*"]
    })
  end

  @impl CiMetrics.Project
  def create_event(%{event_id: event_id, event_type: event_type, raw_event: raw_event}) do
    {:ok, repository} = Repository.from_raw_event(raw_event)

    attrs = %{
      event_id: event_id,
      event_type: event_type,
      repository_id: repository.id,
      raw: raw_event
    }

    Event.insert_or_update(attrs)
  end

  @impl CiMetrics.Project
  def process_event(event), do: EventProcessor.process(event)

  @impl CiMetrics.Project
  def get_events_for(%{repository_id: id}) when is_binary(id) do
    id
    |> Integer.parse()
    |> Tuple.to_list()
    |> List.first()
    |> do_get_events_for_repository()
  end

  def get_events_for(%{repository_id: id}) when is_integer(id) do
    do_get_events_for_repository(id)
  end

  defp do_get_events_for_repository(id) do
    Event
    |> where(repository_id: ^id)
    |> Repo.all()
    |> Repo.preload(:repository)
  end
end
