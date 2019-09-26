defmodule CiMetrics.Project.Push do
  use Ecto.Schema
  import Ecto.Changeset

  alias CiMetrics.Repo
  alias CiMetrics.Project.{Commit, Event, Push}

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

  def from_event(%Event{} = event) do
    event.raw
    |> extract_push_info()
    |> Map.merge(%{repository_id: event.repository_id, event_id: event.id})
    |> Push.insert_or_update()
  end

  defp extract_push_info(raw_event) do
    branch =
      raw_event
      |> Map.get("ref")
      |> String.split("/")
      |> List.last()

    %{branch: branch, before_sha: raw_event["before"], after_sha: raw_event["after"]}
  end

  @doc false
  def changeset(push, attrs) do
    push
    |> cast(attrs, [:branch, :before_sha, :after_sha, :repository_id, :event_id])
    |> validate_required([:branch, :before_sha, :after_sha, :repository_id, :event_id])
  end
end
