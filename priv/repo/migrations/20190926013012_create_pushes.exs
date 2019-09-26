defmodule CiMetrics.Repo.Migrations.CreatePushes do
  use Ecto.Migration

  def change do
    create table(:pushes) do
      add :branch, :string
      add :before_sha, :string
      add :after_sha, :string
      add :repository_id, references(:repositories)
      add :event_id, references(:events)

      timestamps()
    end
  end
end
