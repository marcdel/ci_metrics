defmodule CiMetrics.Project do
  require Logger
  import Ecto.Query, only: [where: 2]

  alias CiMetrics.{GithubClient, Repo}
  alias CiMetrics.Events.{Deployment, DeploymentStatus, Event, EventProcessor, Push}
  alias CiMetrics.Project.Repository

  def create_webhook(repository_name, access_token) do
    GithubClient.create_webhook(%{
      repository_name: repository_name,
      access_token: access_token,
      callback_url: Application.get_env(:ci_metrics, :webhook_callback_url),
      events: ["*"]
    })
  end

  @callback create_event(map()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
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

  @callback process_event(%Event{}) :: %{ok: [Ecto.Schema.t()], error: [Ecto.Changeset.t()]}
  def process_event(%Event{event_type: "push"} = event) do
    EventProcessor.process(%Push{event: event})
  end

  def process_event(%Event{event_type: "deployment"} = event) do
    EventProcessor.process(%Deployment{event: event})
  end

  def process_event(%Event{event_type: "deployment_status"} = event) do
    EventProcessor.process(%DeploymentStatus{event: event})
  end

  def process_event(%Event{event_type: event_type}) do
    Logger.error("Process not defined for #{event_type}")
    %{ok: [], error: []}
  end

  @callback get_events_for(struct()) :: [Event.type()]
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
