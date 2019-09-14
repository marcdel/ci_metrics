defmodule CiMetrics.Project.Event do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [order_by: 2]

  alias CiMetrics.Repo
  alias CiMetrics.Project.Event

  schema "events" do
    field :raw, :map
    field :event_id, :string
    field :event_type, :string
    belongs_to :repository, CiMetrics.Project.Repository
    has_many :commits, CiMetrics.Project.Commit

    timestamps()
  end

  def get_all do
    Event
    |> order_by(desc: :repository_id, desc: :id)
    |> Repo.all()
    |> Repo.preload(:repository)
  end

  def get_by(params) do
    Repo.get_by(Event, params) |> Repo.preload(:repository)
  end

  def raw_event_changeset(event, attrs) do
    event
    |> cast(attrs, [:raw, :event_id, :event_type, :repository_id])
    |> validate_required([:raw, :event_id, :event_type, :repository_id])
    |> foreign_key_constraint(:repository_id)
    |> unique_constraint(:event_id)
  end
end
