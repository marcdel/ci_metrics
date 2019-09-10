defmodule AmadeusCho.Project.Commit do
  use Ecto.Schema
  import Ecto.Changeset
  alias AmadeusCho.Repo

  schema "commits" do
    field :branch, :string
    field :committed_at, :utc_datetime
    field :sha, :string
    belongs_to :repository, AmadeusCho.Project.Repository
    belongs_to :event, AmadeusCho.Project.Event

    timestamps()
  end

  def get_all do
    Repo.all(AmadeusCho.Project.Commit)
  end

  def changeset(commit, attrs) do
    commit
    |> cast(attrs, [:sha, :branch, :committed_at, :repository_id, :event_id])
    |> validate_required([:sha, :branch, :committed_at, :repository_id, :event_id])
    |> unique_constraint(:sha)
  end
end
