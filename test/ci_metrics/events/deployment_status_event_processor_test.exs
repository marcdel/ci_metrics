defmodule CiMetrics.Events.DeploymentStatusEventProcessorTest do
  use CiMetrics.DataCase, async: true

  alias CiMetrics.Events.{EventProcessor, Deployment, DeploymentStatus}

  describe "process/1" do
    test "can process deployment events" do
      %{ok: [deployment], error: []} =
        EventProcessor.process(%Deployment{event: CreateEvent.deployment()})

      event = CreateEvent.deployment_status()

      %{ok: [deployment_status], error: []} =
        EventProcessor.process(%DeploymentStatus{event: event})

      assert deployment_status.deployment_status_id == 239_119_259
      assert deployment_status.deployment_id == deployment.deployment_id
      assert deployment_status.status == "success"
      assert DateTime.to_string(deployment_status.status_at) == "2019-09-08 21:56:58Z"
      assert deployment_status.event_id == event.id

      [deployment] = Deployment.get_all() |> CiMetrics.Repo.preload(:deployment_statuses)
      [^deployment_status] = deployment.deployment_statuses
    end
  end
end
