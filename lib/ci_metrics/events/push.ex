defmodule CiMetrics.Events.Push do
  use Ecto.Schema
  import Ecto.Changeset

  alias CiMetrics.Repo
  alias CiMetrics.Events.{Push}
  alias CiMetrics.Project.{Commit, Event, Repository}

  schema "pushes" do
    field :branch, :string
    field :before_sha, :string
    field :after_sha, :string

    belongs_to :event, Event
    belongs_to :repository, Repository

    has_many :commits, Commit

    timestamps()
  end

  def get_all do
    Push
    |> Repo.all()
    |> Repo.preload(:commits)
  end

  def insert_or_update(params) do
    case Repo.get_by(Push, params) do
      nil -> %Push{}
      push -> push
    end
    |> changeset(params)
    |> Repo.insert_or_update()
  end

  @doc false
  def changeset(push, attrs) do
    push
    |> cast(attrs, [:branch, :before_sha, :after_sha, :repository_id, :event_id])
    |> validate_required([:branch, :before_sha, :after_sha, :repository_id, :event_id])
    |> foreign_key_constraint(:repository_id)
    |> foreign_key_constraint(:event_id)
  end
end
