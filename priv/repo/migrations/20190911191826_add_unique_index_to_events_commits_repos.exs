defmodule AmadeusCho.Repo.Migrations.AddUniqueIndexToEventsAndCommits do
  use Ecto.Migration

  def change do
    create unique_index(:commits, [:sha])
    create unique_index(:events, [:event_id])
    create unique_index(:repositories, [:name, :owner])
  end
end
