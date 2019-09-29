defmodule CiMetrics.Project.Commit do
  use Ecto.Schema
  import Ecto.Changeset
  alias CiMetrics.Repo
  alias CiMetrics.Events.{Push}
  alias CiMetrics.Project.{Commit, Event, Repository}

  schema "commits" do
    field :branch, :string
    field :committed_at, :utc_datetime
    field :sha, :string
    belongs_to :push, Push
    belongs_to :repository, Repository
    belongs_to :event, Event

    timestamps()
  end

  def get_all do
    Repo.all(Commit)
  end

  def insert_or_update(params) do
    case Repo.get_by(Commit, params) do
      nil -> %Commit{}
      commit -> commit
    end
    |> changeset(params)
    |> Repo.insert_or_update()
  end

  def changeset(commit, attrs) do
    commit
    |> cast(attrs, [:sha, :branch, :committed_at, :repository_id, :event_id, :push_id])
    |> validate_required([:sha, :branch, :committed_at, :repository_id, :event_id, :push_id])
    |> foreign_key_constraint(:repository_id)
    |> foreign_key_constraint(:event_id)
    |> foreign_key_constraint(:push_id)
    |> unique_constraint(:sha)
  end
end
