defmodule CiMetrics.Events.EventProcessorTest do
  use CiMetrics.DataCase, async: true

  alias CiMetrics.Events.{EventProcessor, Deployment, DeploymentStatus}
  alias CiMetrics.Project.Commit

  test "process/1" do
    event = CreateEvent.create("push")
    %{ok: [%Commit{}], error: []} = EventProcessor.process(event)

    event = CreateEvent.create("deployment")
    %{ok: [%Deployment{}], error: []} = EventProcessor.process(event)

    event = CreateEvent.create("deployment_status")
    %{ok: [%DeploymentStatus{}], error: []} = EventProcessor.process(event)
  end

  test "handles unknown event types" do
    event = CreateEvent.create("unknown_event")
    assert %{ok: [], error: []} = EventProcessor.process(event)
  end
end
