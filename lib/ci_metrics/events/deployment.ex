defmodule CiMetrics.Events.Deployment do
  use Ecto.Schema
  import Ecto.Changeset
  alias CiMetrics.Repo
  alias CiMetrics.Events.{Event, Deployment, DeploymentStatus}
  alias CiMetrics.Project.Repository

  schema "deployments" do
    field :deployment_id, :integer
    field :sha, :string
    field :started_at, :utc_datetime
    belongs_to :event, Event
    belongs_to :repository, Repository

    has_many :deployment_statuses, DeploymentStatus,
      foreign_key: :deployment_id,
      references: :deployment_id

    timestamps()
  end

  def get_all do
    Repo.all(Deployment)
  end

  def insert_or_update(params) do
    case Repo.get_by(Deployment, params) do
      nil -> %Deployment{}
      deployment -> deployment
    end
    |> changeset(params)
    |> Repo.insert_or_update()
  end

  @doc false
  def changeset(deployment, attrs) do
    deployment
    |> cast(attrs, [:deployment_id, :sha, :started_at, :repository_id, :event_id])
    |> validate_required([:deployment_id, :sha, :started_at, :repository_id, :event_id])
    |> foreign_key_constraint(:repository_id)
    |> foreign_key_constraint(:event_id)
    |> unique_constraint(:deploymeny_id)
  end
end
