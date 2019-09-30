defimpl CiMetrics.Events.EventProcessor, for: CiMetrics.Events.DeploymentStatus do
  require Logger

  alias CiMetrics.Events.DeploymentStatus

  def process(%DeploymentStatus{event: event}) do
    case DeploymentStatus.from_event(event) do
      {:ok, %DeploymentStatus{} = deployment_status} ->
        %{ok: [deployment_status], error: []}

      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.error("Unable to save deployment_status: #{inspect(changeset)}")
        %{ok: [], error: [changeset]}
    end
  end
end
