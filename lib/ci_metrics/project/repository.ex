defmodule CiMetrics.Project.Repository do
  use Ecto.Schema
  import Ecto.Changeset

  alias CiMetrics.Repo
  # This name is not confusing at all
  alias CiMetrics.Project.Repository

  schema "repositories" do
    field :name, :string
    field :owner, :string
    field :deployment_strategy, :string
    has_many :events, CiMetrics.Events.Event
    has_many :commits, CiMetrics.Project.Commit
    has_many :deployments, CiMetrics.Events.Deployment

    timestamps()
  end

  def full_name(%{owner: owner, name: name}) do
    "#{owner}/#{name}"
  end

  def get(id) when is_binary(id) do
    id
    |> Integer.parse()
    |> Tuple.to_list()
    |> List.first()
    |> get()
  end

  def get(id) when is_integer(id) do
    Repo.get(Repository, id)
  end

  def get_by(params) do
    Repo.get_by(Repository, params)
  end

  def get_all do
    Repo.all(Repository)
  end

  def insert_or_update(params) do
    case Repo.get_by(Repository, params) do
      nil -> %Repository{}
      repository -> repository
    end
    |> changeset(params)
    |> Repo.insert_or_update()
  end

  def from_raw_event(raw_event) do
    raw_event
    |> extract_repository_info()
    |> Repository.insert_or_update()
  end

  def changeset(repository, attrs) do
    repository
    |> cast(attrs, [:name, :owner, :deployment_strategy])
    |> validate_required([:name, :owner])
    |> unique_constraint(:name, name: :repositories_name_owner_index)
  end

  defp extract_repository_info(raw_event) do
    repository_full_name = Kernel.get_in(raw_event, ["repository", "full_name"])
    git_url = Kernel.get_in(raw_event, ["repository", "git_url"])

    [owner, name] = parse_repository_name(repository_full_name, git_url)

    %{owner: owner, name: name}
  end

  defp parse_repository_name(nil, git_url) do
    git_url
    |> URI.parse()
    |> Map.get(:path)
    |> Path.rootname()
    |> Path.relative()
    |> Path.split()
  end

  defp parse_repository_name(repository_full_name, _) do
    String.split(repository_full_name, "/")
  end
end
