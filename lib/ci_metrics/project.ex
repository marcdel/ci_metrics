defmodule CiMetrics.Project do
  @callback create_event(map()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  @callback process_event(%CiMetrics.Events.Event{}) :: %{
              ok: [Ecto.Schema.t()],
              error: [Ecto.Changeset.t()]
            }
  @callback get_events_for(struct()) :: [CiMetrics.Events.Event.type()]
  @callback calculate_lead_time(integer()) :: %CiMetrics.Metrics.TimeUnitMetric{}
  @callback daily_lead_time_snapshots(integer()) :: [%CiMetrics.Metrics.TimeUnitMetric{}]
end
