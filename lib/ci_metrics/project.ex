defmodule CiMetrics.Project do
  require Logger
  import Ecto.Query, only: [where: 2]

  alias CiMetrics.{GithubClient, Repo}
  alias CiMetrics.Project.{Commit, Event, Repository}

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
    {:ok, repository} =
      raw_event
      |> extract_repository_info()
      |> Repository.insert_or_update()

    attrs = %{
      event_id: event_id,
      event_type: event_type,
      repository_id: repository.id,
      raw: raw_event
    }

    %Event{}
    |> Event.raw_event_changeset(attrs)
    |> Repo.insert(returning: true)
  end

  @callback process_event(%Event{}) :: %{ok: [Ecto.Schema.t()], error: [Ecto.Changeset.t()]}
  def process_event(%Event{event_type: "push"} = event) do
    event.raw
    |> extract_commit_info()
    |> Enum.map(fn raw_commit ->
      Map.merge(raw_commit, %{repository_id: event.repository_id, event_id: event.id})
    end)
    |> Enum.map(fn raw_commit -> Commit.insert_or_update(raw_commit) end)
    |> Enum.reduce(%{ok: [], error: []}, fn
      {:ok, commit}, result ->
        %{result | ok: [commit | result.ok]}

      {:error, changeset}, result ->
        Logger.error("Unable to save commit: #{inspect(changeset)}")
        %{result | error: [changeset | result.error]}
    end)
  end

  def process_event(%Event{event_type: event_type}) do
    Logger.error("Process not defined for #{event_type}")
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

  defp do_get_events_for_repository(id) when is_integer(id) do
    Event
    |> where(repository_id: ^id)
    |> Repo.all()
    |> Repo.preload(:repository)
  end

  defp extract_repository_info(raw_event) do
    repository_full_name = Kernel.get_in(raw_event, ["repository", "full_name"])
    git_url = Kernel.get_in(raw_event, ["repository", "git_url"])

    [owner, name] = parse_repository_name(repository_full_name, git_url)

    %{owner: owner, name: name}
  end

  defp extract_commit_info(raw_event) do
    branch =
      raw_event
      |> Map.get("ref")
      |> String.split("/")
      |> List.last()

    raw_event
    |> Map.get("commits")
    |> Enum.map(fn commit ->
      {:ok, committed_at, _offset_in_seconds} = DateTime.from_iso8601(commit["timestamp"])
      %{sha: commit["id"], branch: branch, committed_at: committed_at}
    end)
  end

  defp parse_repository_name(nil, git_url) do
    git_url
    |> URI.parse()
    |> Map.get(:path)
    |> Path.rootname()
    |> Path.relative()
    |> Path.split()
  end

  defp parse_repository_name(repository_full_name, _) do
    String.split(repository_full_name, "/")
  end
end
