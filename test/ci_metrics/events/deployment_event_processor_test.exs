defmodule CiMetrics.Events.DeploymentEventProcessorTest do
  use CiMetrics.DataCase, async: true

  alias CiMetrics.Events.{EventProcessor, Deployment}

  describe "process/1" do
    test "can process deployment events" do
      event = CreateEvent.deployment()

      %{ok: [deployment], error: []} = EventProcessor.process(%Deployment{event: event})

      assert deployment.deployment_id == 167_780_832
      assert deployment.sha == "eb475e393647070a6b0273b9d284dbc535bb4d7a"
      assert DateTime.to_string(deployment.started_at) == "2019-09-08 21:55:48Z"

      assert deployment.event_id != nil
      assert deployment.repository_id != nil
    end
  end
end
