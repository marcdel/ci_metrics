defmodule CiMetrics.Repo.Migrations.MakePushesBeforeShaNullable do
  use Ecto.Migration

  def change do
    alter table(:pushes) do
      modify :before_sha, :string, null: true
    end
  end
end
