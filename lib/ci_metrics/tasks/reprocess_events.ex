defmodule Mix.Tasks.ReprocessEvents do
  use Mix.Task

  @shortdoc "Reprocesses all events to create the associated objects."
  def run(_) do
    Mix.Task.run("app.start")

    CiMetrics.Events.Event.get_all()
    |> Enum.map(&CiMetrics.Project.process_event/1)
  end
end
