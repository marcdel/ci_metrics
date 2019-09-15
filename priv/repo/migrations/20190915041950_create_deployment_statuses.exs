defmodule CiMetrics.Repo.Migrations.CreateDeploymentStatuses do
  use Ecto.Migration

  def change do
    create table(:deployment_statuses) do
      add :deployment_status_id, :integer
      add :status, :string
      add :status_at, :utc_datetime
      add :deployment_id, references(:deployments, column: :deployment_id)
      add :event_id, references(:events)

      timestamps()
    end

    create unique_index(:deployment_statuses, [:deployment_status_id])
  end
end
