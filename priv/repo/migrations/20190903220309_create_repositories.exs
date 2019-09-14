defmodule CiMetrics.Repo.Migrations.CreateRepositories do
  use Ecto.Migration

  def change do
    create table(:repositories) do
      add :name, :string
      add :owner, :string

      timestamps()
    end
  end
end
