defmodule CiMetrics.Project.Repository do
  use Ecto.Schema
  import Ecto.Changeset

  alias CiMetrics.Repo
  # This name is not confusing at all
  alias CiMetrics.Project.Repository

  schema "repositories" do
    field :name, :string
    field :owner, :string
    has_many :events, CiMetrics.Project.Event
    has_many :commits, CiMetrics.Project.Commit

    timestamps()
  end

  def get_by(params) do
    Repo.get_by(Repository, params)
  end

  def insert_or_update(params) do
    case Repo.get_by(Repository, params) do
      nil -> %Repository{}
      repository -> repository
    end
    |> changeset(params)
    |> Repo.insert_or_update()
  end

  def get_all do
    Repo.all(Repository)
  end

  def changeset(repository, attrs) do
    repository
    |> cast(attrs, [:name, :owner])
    |> validate_required([:name, :owner])
    |> unique_constraint(:name, name: :repositories_name_owner_index)
  end
end