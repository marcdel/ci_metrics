defmodule AmadeusCho.Event do
  use Ecto.Schema
  import Ecto.Changeset
  alias AmadeusCho.{Event, Repo}

  schema "events" do
    field :raw, :map
    field :event_id, :string
    field :event_type, :string
    timestamps()
  end

  def create_event(attrs \\ %{}) do
    %Event{}
    |> raw_event_changeset(attrs)
    |> Repo.insert()
  end

  def find_all do
    Repo.all(Event)
  end

  @doc false
  def raw_event_changeset(event, attrs) do
    event
    |> cast(attrs, [:raw, :event_id, :event_type])
    |> validate_required([:raw, :event_id, :event_type])
    |> unique_constraint(:event_id)
  end
end
