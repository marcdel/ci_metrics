defmodule CreateEvent do
  alias CiMetrics.GithubProject

  def create_and_process(event_name, params \\ %{}) do
    event_name
    |> create(params)
    |> GithubProject.process_event()
  end

  def create(event_name), do: create(event_name, %{})

  def create("push", params) do
    raw_event = %{
      "ref" => Map.get(params, "ref", "refs/heads/master"),
      "before" => Map.get(params, "before", Ecto.UUID.generate()),
      "after" => Map.get(params, "after", Ecto.UUID.generate()),
      "repository" =>
        Map.merge(
          %{"full_name" => "group/repository"},
          Map.get(params, "repository", %{})
        ),
      "commits" =>
        Map.get(params, "commits", [
          %{
            "id" => Ecto.UUID.generate(),
            "timestamp" => "2019-09-06 03:26:10Z"
          }
        ])
    }

    {:ok, event} =
      GithubProject.create_event(%{
        event_id: Ecto.UUID.generate(),
        event_type: "push",
        raw_event: raw_event
      })

    event
  end

  def create("deployment", params) do
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

    event
  end

  def create("deployment_status", params) do
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

    event
  end

  def create("unknown_event", params) do
    raw_event = %{
      "repository" =>
        Map.merge(
          %{"full_name" => "group/repository"},
          Map.get(params, "repository", %{})
        )
    }

    {:ok, event} =
      GithubProject.create_event(%{
        event_id: Ecto.UUID.generate(),
        event_type: "unknown_event",
        raw_event: raw_event
      })

    event
  end

  def multi_push do
    create_from_json("push", "../support/fixtures/multi_push.json")
  end

  def deployment do
    create_from_json("deployment", "../support/fixtures/deployment.json")
  end

  def deployment_status do
    create_from_json("deployment_status", "../support/fixtures/deployment_status_success.json")
  end

  defp create_from_json(event_type, file_path) do
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
end
