defmodule CiMetrics.Repo.Migrations.CreateDeployments do
  use Ecto.Migration

  def change do
    create table(:deployments) do
      add :deployment_id, :integer
      add :sha, :string
      add :started_at, :utc_datetime
      add :event_id, references(:events)
      add :repository_id, references(:repositories)

      timestamps()
    end

    create unique_index(:deployments, [:deployment_id])
  end
end
