defmodule CiMetrics.Repo.Migrations.CreateCommits do
  use Ecto.Migration

  def change do
    create table(:commits) do
      add :sha, :string, unique: true
      add :branch, :string
      add :committed_at, :utc_datetime
      add :repository_id, references(:repositories)
      add :event_id, references(:events)

      timestamps()
    end
  end
end
