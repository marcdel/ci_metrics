defmodule CiMetrics.Project do
  require Logger
  import Ecto.Query, only: [where: 2]

  alias CiMetrics.{GithubClient, Repo}
  alias CiMetrics.Events.{Deployment, Event, EventProcessor, Push}
  alias CiMetrics.Project.{DeploymentStatus, Repository}

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
    event
    |> cast_event()
    |> EventProcessor.process()
  end

  def process_event(%Event{event_type: "deployment"} = event) do
    case Deployment.from_event(event) do
      {:ok, %Deployment{} = deployment} ->
        %{ok: [deployment], error: []}

      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.error("Unable to save deployment: #{inspect(changeset)}")
        %{ok: [], error: [changeset]}
    end
  end

  def process_event(%Event{event_type: "deployment_status"} = event) do
    case DeploymentStatus.from_event(event) do
      {:ok, %DeploymentStatus{} = deployment_status} ->
        %{ok: [deployment_status], error: []}

      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.error("Unable to save deployment_status: #{inspect(changeset)}")
        %{ok: [], error: [changeset]}
    end
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

  defp cast_event(generic_event) do
    case generic_event.event_type do
      "push" -> %Push{event: generic_event}
    end
  end
end
