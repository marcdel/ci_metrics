defmodule CiMetrics.Metrics.MetricSnapshot do
  use Ecto.Schema
  import Ecto.Changeset

  alias CiMetrics.Project.Repository

  schema "metric_snapshots" do
    field :average_lead_time, :integer
    belongs_to :repository, Repository

    timestamps()
  end

  @doc false
  def changeset(push, attrs) do
    push
    |> cast(attrs, [:average_lead_time, :repository_id])
    |> validate_required([:average_lead_time, :repository_id])
    |> foreign_key_constraint(:repository_id)
  end
end
