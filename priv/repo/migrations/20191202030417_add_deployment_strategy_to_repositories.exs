defmodule CiMetrics.Repo.Migrations.AddDeploymentStrategyToRepositories do
  use Ecto.Migration

  def change do
    alter table(:repositories) do
      add :deployment_strategy, :string
    end
  end
end
