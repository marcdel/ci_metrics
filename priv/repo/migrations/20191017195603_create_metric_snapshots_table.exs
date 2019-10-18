defmodule CiMetrics.Repo.Migrations.CreateMetricSnapshotsTable do
  use Ecto.Migration

  def change do
    create table(:metric_snapshots) do
      add :repository_id, references(:repositories)
      add :average_lead_time, :bigint

      timestamps()
    end
  end
end
