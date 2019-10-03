defmodule CreateEvent do
  alias CiMetrics.GithubProject

  def create_and_process(event_type, file_path) do
    GithubProject.process_event(create(event_type, file_path))
  end

  def create(event_type, file_path) do
    raw_event =
      file_path
      |> Path.expand(__DIR__)
      |> File.read!()
      |> Jason.decode!()

    {:ok, event} =
      GithubProject.create_event(%{
        event_id: Ecto.UUID.generate(),
        event_type: event_type,
        raw_event: raw_event
      })

    event
  end

  def push do
    create("push", "../support/fixtures/push.json")
  end

  def second_push do
    create("push", "../support/fixtures/second_push.json")
  end

  def multi_push do
    create("push", "../support/fixtures/multi_push.json")
  end

  def deployment do
    create("deployment", "../support/fixtures/deployment.json")
  end

  def second_deployment do
    create("deployment", "../support/fixtures/second_deployment.json")
  end

  def deployment_status do
    create("deployment_status", "../support/fixtures/deployment_status_success.json")
  end

  def second_deployment_status do
    create("deployment_status", "../support/fixtures/second_deployment_status_success.json")
  end
end
