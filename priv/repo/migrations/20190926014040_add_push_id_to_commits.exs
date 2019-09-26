defmodule CiMetrics.Repo.Migrations.AddPushIdToCommits do
  use Ecto.Migration

  def change do
    alter table(:commits) do
      add :push_id, references(:pushes)
    end
  end
end
