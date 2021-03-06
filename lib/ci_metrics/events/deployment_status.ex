defmodule CiMetrics.Events.DeploymentStatus do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias CiMetrics.Repo
  alias CiMetrics.Events.{Deployment, DeploymentStatus, Event}

  schema "deployment_statuses" do
    field :deployment_status_id, :integer
    field :status, :string
    field :status_at, :utc_datetime
    belongs_to :deployment, Deployment, foreign_key: :deployment_id, references: :deployment_id
    belongs_to :event, Event

    timestamps()
  end

  def get_all do
    Repo.all(DeploymentStatus)
  end

  def get_successful_deployment_statuses_for(repository_id) do
    query =
      from status in DeploymentStatus,
        join: deployment in Deployment,
        on: deployment.deployment_id == status.deployment_id,
        where:
          deployment.repository_id == ^repository_id and
            status.status == "success",
        order_by: [desc: status.status_at],
        select: status

    Repo.all(query)
  end

  def insert_or_update(params) do
    case Repo.get_by(DeploymentStatus, params) do
      nil -> %DeploymentStatus{}
      status -> status
    end
    |> changeset(params)
    |> Repo.insert_or_update()
  end

  def from_event(%Event{} = event) do
    event.raw
    |> extract_deployment_status_info()
    |> Map.put(:event_id, event.id)
    |> DeploymentStatus.insert_or_update()
  end

  defp extract_deployment_status_info(raw_event) do
    deployment = raw_event["deployment"]
    deployment_status = raw_event["deployment_status"]
    {:ok, status_at, _offset_in_seconds} = DateTime.from_iso8601(deployment_status["created_at"])

    %{
      deployment_status_id: deployment_status["id"],
      deployment_id: deployment["id"],
      status: deployment_status["state"],
      status_at: status_at
    }
  end

  @doc false
  def changeset(deployment_status, attrs) do
    deployment_status
    |> cast(attrs, [:deployment_status_id, :deployment_id, :event_id, :status, :status_at])
    |> validate_required([:deployment_status_id, :deployment_id, :event_id, :status, :status_at])
    |> foreign_key_constraint(:deployment_id)
    |> foreign_key_constraint(:event_id)
    |> unique_constraint(:deployment_status_id)
  end
end
