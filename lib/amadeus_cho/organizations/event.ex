defmodule AmadeusCho.Event do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [order_by: 2, where: 2]

  alias AmadeusCho.{Event, Repo}

  schema "events" do
    field :raw, :map
    field :event_id, :string
    field :event_type, :string
    belongs_to :repository, AmadeusCho.Repository
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

  @doc false
  def raw_event_changeset(event, attrs) do
    event
    |> cast(attrs, [:raw, :event_id, :event_type, :repository_id])
    |> validate_required([:raw, :event_id, :event_type, :repository_id])
    |> unique_constraint(:event_id)
  end
end
