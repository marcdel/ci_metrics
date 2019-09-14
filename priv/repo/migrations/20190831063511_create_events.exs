defmodule CiMetrics.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events) do
      add :raw, :map
      add :event_id, :string, unique: true
      add :event_type, :string

      timestamps()
    end
  end
end
