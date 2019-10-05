defmodule CreateEvent do
  alias CiMetrics.GithubProject

  def create_and_process2("push", params) do
    raw_event = %{
      "ref" => Map.get(params, "ref", "refs/heads/master"),
      "before" => Map.get(params, "before", Ecto.UUID.generate()),
      "after" => Map.get(params, "after", Ecto.UUID.generate()),
      "repository" =>
        Map.merge(
          %{"full_name" => "group/repository"},
          Map.get(params, "repository", %{})
        ),
      "commits" => [
        %{
          "id" => Ecto.UUID.generate(),
          "timestamp" => "2019-09-06 03:26:10Z"
        }
      ]
    }

    {:ok, event} =
      GithubProject.create_event(%{
        event_id: Ecto.UUID.generate(),
        event_type: "push",
        raw_event: raw_event
      })

    GithubProject.process_event(event)
  end

  def create_and_process2("deployment", params) do
    raw_event = %{
      "deployment" =>
        Map.merge(
          %{
            "id" => 167_780_832,
            "sha" => Ecto.UUID.generate(),
            "created_at" => "2019-09-06 03:26:10Z"
          },
          Map.get(params, "deployment", %{})
        ),
      "repository" =>
        Map.merge(
          %{"full_name" => "group/repository"},
          Map.get(params, "repository", %{})
        )
    }

    {:ok, event} =
      GithubProject.create_event(%{
        event_id: Ecto.UUID.generate(),
        event_type: "deployment",
        raw_event: raw_event
      })

    GithubProject.process_event(event)
  end

  def create_and_process2("deployment_status", params) do
    raw_event = %{
      "deployment_status" =>
        Map.merge(
          %{
            "id" => 239_119_259,
            "state" => "success",
            "created_at" => "2019-09-06 03:26:10Z"
          },
          Map.get(params, "deployment_status", %{})
        ),
      "repository" =>
        Map.merge(
          %{"full_name" => "group/repository"},
          Map.get(params, "repository", %{})
        ),
      "deployment" =>
        Map.merge(
          %{
            "id" => 167_780_832,
            "sha" => Ecto.UUID.generate()
          },
          Map.get(params, "deployment", %{})
        )
    }

    {:ok, event} =
      GithubProject.create_event(%{
        event_id: Ecto.UUID.generate(),
        event_type: "deployment_status",
        raw_event: raw_event
      })

    GithubProject.process_event(event)
  end

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
