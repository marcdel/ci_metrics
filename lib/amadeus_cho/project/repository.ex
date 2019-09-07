defmodule AmadeusCho.Project.Repository do
  use Ecto.Schema
  import Ecto.Changeset

  alias AmadeusCho.Repo
  # This name is not confusing at all
  alias AmadeusCho.Project.Repository

  schema "repositories" do
    field :name, :string
    field :owner, :string
    has_many :events, AmadeusCho.Project.Event

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

  @doc false
  def changeset(repository, attrs) do
    repository
    |> cast(attrs, [:name, :owner])
    |> validate_required([:name, :owner])
  end
end