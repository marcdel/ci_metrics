defmodule CiMetrics.Project.Commit do
  use Ecto.Schema
  import Ecto.Changeset
  alias CiMetrics.Repo
  alias CiMetrics.Project.{Commit, Event, Push, Repository}

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

  def from_event(%Event{} = event, push_id) do
    event.raw
    |> extract_commit_info()
    |> Enum.map(fn raw_commit ->
      Map.merge(raw_commit, %{
        repository_id: event.repository_id,
        event_id: event.id,
        push_id: push_id
      })
    end)
    |> Enum.map(fn raw_commit -> Commit.insert_or_update(raw_commit) end)
  end

  defp extract_commit_info(raw_event) do
    branch =
      raw_event
      |> Map.get("ref")
      |> String.split("/")
      |> List.last()

    raw_event
    |> Map.get("commits")
    |> Enum.map(fn commit ->
      {:ok, committed_at, _offset_in_seconds} = DateTime.from_iso8601(commit["timestamp"])
      %{sha: commit["id"], branch: branch, committed_at: committed_at}
    end)
  end

  def changeset(commit, attrs) do
    commit
    |> cast(attrs, [:sha, :branch, :committed_at, :repository_id, :event_id, :push_id])
    |> validate_required([:sha, :branch, :committed_at, :repository_id, :event_id, :push_id])
    |> foreign_key_constraint(:repository_id)
    |> foreign_key_constraint(:event_id)
    |> unique_constraint(:sha)
  end
end
