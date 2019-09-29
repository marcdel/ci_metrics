defimpl CiMetrics.Events.EventProcessor, for: CiMetrics.Events.Deployment do
  require Logger

  alias CiMetrics.Events.{Deployment, Event}

  def process(%Deployment{event: event}) do
    case from_event(event) do
      {:ok, %Deployment{} = deployment} ->
        %{ok: [deployment], error: []}

      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.error("Unable to save deployment: #{inspect(changeset)}")
        %{ok: [], error: [changeset]}
    end
  end

  def from_event(%Event{} = event) do
    event.raw
    |> extract_deployment_info()
    |> Map.merge(%{repository_id: event.repository_id, event_id: event.id})
    |> Deployment.insert_or_update()
  end

  defp extract_deployment_info(raw_event) do
    deployment = raw_event["deployment"]
    {:ok, started_at, _offset_in_seconds} = DateTime.from_iso8601(deployment["created_at"])

    %{
      deployment_id: deployment["id"],
      sha: deployment["sha"],
      started_at: started_at
    }
  end
end
