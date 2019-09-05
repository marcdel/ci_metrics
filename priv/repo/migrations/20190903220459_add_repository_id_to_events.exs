defmodule AmadeusCho.Repo.Migrations.AddRepositoryIdToEvents do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add :repository_id, references(:repositories)
    end
  end
end
