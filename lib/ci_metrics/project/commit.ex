defmodule CiMetrics.Project.Commit do
  use Ecto.Schema
  import Ecto.Changeset
  alias CiMetrics.Repo

  schema "commits" do
    field :branch, :string
    field :committed_at, :utc_datetime
    field :sha, :string
    belongs_to :repository, CiMetrics.Project.Repository
    belongs_to :event, CiMetrics.Project.Event

    timestamps()
  end

  def insert_or_update(params) do
    case Repo.get_by(CiMetrics.Project.Commit, params) do
      nil -> %CiMetrics.Project.Commit{}
      commit -> commit
    end
    |> changeset(params)
    |> Repo.insert_or_update()
  end

  def get_all do
    Repo.all(CiMetrics.Project.Commit)
  end

  def changeset(commit, attrs) do
    commit
    |> cast(attrs, [:sha, :branch, :committed_at, :repository_id, :event_id])
    |> validate_required([:sha, :branch, :committed_at, :repository_id, :event_id])
    |> foreign_key_constraint(:repository_id)
    |> foreign_key_constraint(:event_id)
    |> unique_constraint(:sha)
  end
end
