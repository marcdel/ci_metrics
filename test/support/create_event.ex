defmodule CreateEvent do
  alias CiMetrics.Project

  def push do
    raw_event =
      "../support/fixtures/push.json"
      |> Path.expand(__DIR__)
      |> File.read!()
      |> Jason.decode!()

    {:ok, event} =
      Project.create_event(%{
        event_id: Ecto.UUID.generate(),
        event_type: "push",
        raw_event: raw_event
      })

    event
  end

  def multi_push do
    raw_event =
      "../support/fixtures/multi_push.json"
      |> Path.expand(__DIR__)
      |> File.read!()
      |> Jason.decode!()

    {:ok, event} =
      Project.create_event(%{
        event_id: Ecto.UUID.generate(),
        event_type: "push",
        raw_event: raw_event
      })

    event
  end

  def deployment do
    raw_event =
      "../support/fixtures/deployment.json"
      |> Path.expand(__DIR__)
      |> File.read!()
      |> Jason.decode!()

    {:ok, event} =
      Project.create_event(%{
        event_id: Ecto.UUID.generate(),
        event_type: "deployment",
        raw_event: raw_event
      })

    event
  end

  def deployment_status do
    raw_event =
      "../support/fixtures/deployment_status.json"
      |> Path.expand(__DIR__)
      |> File.read!()
      |> Jason.decode!()

    {:ok, event} =
      Project.create_event(%{
        event_id: Ecto.UUID.generate(),
        event_type: "deployment_status",
        raw_event: raw_event
      })

    event
  end
end
