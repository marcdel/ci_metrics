defmodule CiMetrics.Project do
  @callback create_event(map()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  @callback process_event(%CiMetrics.Events.Event{}) :: %{
              ok: [Ecto.Schema.t()],
              error: [Ecto.Changeset.t()]
            }
  @callback get_events_for(struct()) :: [CiMetrics.Events.Event.type()]
end
