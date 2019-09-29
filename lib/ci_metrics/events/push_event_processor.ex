defimpl CiMetrics.Events.EventProcessor, for: CiMetrics.Events.Push do
  require Logger

  alias CiMetrics.Events.{Push}
  alias CiMetrics.Project.Commit

  def process(%Push{event: event}) do
    {:ok, push} = push_from_event(event)

    commit_from_event(event, push.id)
    |> Enum.reduce(%{ok: [], error: []}, fn
      {:ok, commit}, result ->
        %{result | ok: [commit | result.ok]}

      {:error, changeset}, result ->
        Logger.error("Unable to save commit: #{inspect(changeset)}")
        %{result | error: [changeset | result.error]}
    end)
  end

  defp push_from_event(event) do
    event.raw
    |> extract_push_info()
    |> Map.merge(%{repository_id: event.repository_id, event_id: event.id})
    |> Push.insert_or_update()
  end

  defp extract_push_info(raw_event) do
    branch =
      raw_event
      |> Map.get("ref")
      |> String.split("/")
      |> List.last()

    %{branch: branch, before_sha: raw_event["before"], after_sha: raw_event["after"]}
  end

  def commit_from_event(event, push_id) do
    event.raw
    |> extract_commit_info()
    |> Enum.map(fn raw_commit ->
      Map.merge(raw_commit, %{
        repository_id: event.repository_id,
        event_id: event.id,
        push_id: push_id
      })
    end)
    |> Enum.map(fn raw_commit -> Commit.insert_or_update(raw_commit) end)
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
end
