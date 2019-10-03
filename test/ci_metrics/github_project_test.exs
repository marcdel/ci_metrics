defmodule CiMetrics.GithubProjectTest do
  use CiMetrics.DataCase, async: true

  alias CiMetrics.Events.{Event, Deployment, DeploymentStatus}
  alias CiMetrics.GithubProject
  alias CiMetrics.Project.{Commit, Repository}

  describe "create_event/3" do
    test "creates an event with the id, type and raw event" do
      event_id = "05b648a1-86cd-4777-bd5c-2e12302d75d3"
      event_type = "push"

      raw_event =
        "../support/push.json"
        |> Path.expand(__DIR__)
        |> File.read!()
        |> Jason.decode!()

      GithubProject.create_event(%{
        event_id: event_id,
        event_type: event_type,
        raw_event: raw_event
      })

      [event] = Event.get_all()
      assert event.event_id == "05b648a1-86cd-4777-bd5c-2e12302d75d3"
      assert event.event_type == "push"
      assert event.raw == raw_event
    end

    test "creates a repository if one isn't found and associates it with the event" do
      event_id = "05b648a1-86cd-4777-bd5c-2e12302d75d3"
      event_type = "push"

      raw_event =
        "../support/push.json"
        |> Path.expand(__DIR__)
        |> File.read!()
        |> Jason.decode!()

      GithubProject.create_event(%{
        event_id: event_id,
        event_type: event_type,
        raw_event: raw_event
      })

      [repository] = Repository.get_all()
      assert repository.name == "ci_metrics_test"
      assert repository.owner == "marcdel"

      [event] = Event.get_all()
      assert event.repository_id == repository.id
    end

    test "cannot create the same event twice" do
      event_type = "push"

      raw_event =
        "../support/push.json"
        |> Path.expand(__DIR__)
        |> File.read!()
        |> Jason.decode!()

      assert {:ok, event} =
               GithubProject.create_event(%{
                 event_id: "same-event-id",
                 event_type: event_type,
                 raw_event: raw_event
               })

      assert {:ok, ^event} =
               GithubProject.create_event(%{
                 event_id: "same-event-id",
                 event_type: event_type,
                 raw_event: raw_event
               })

      assert Event.get_all() |> Enum.count() == 1
    end
  end

  describe "process_event/1" do
    test "can process different types of events" do
      event = CreateEvent.push()
      %{ok: [%Commit{}], error: []} = GithubProject.process_event(event)

      event = CreateEvent.deployment()
      %{ok: [%Deployment{}], error: []} = GithubProject.process_event(event)

      event = CreateEvent.deployment_status()
      %{ok: [%DeploymentStatus{}], error: []} = GithubProject.process_event(event)
    end

    test "handles unknown event types" do
      raw_event =
        "../support/fixtures/unknown_event.json"
        |> Path.expand(__DIR__)
        |> File.read!()
        |> Jason.decode!()

      {:ok, event} =
        GithubProject.create_event(%{
          event_id: "asdasd",
          event_type: "unknown_type",
          raw_event: raw_event
        })

      assert %{ok: [], error: []} = GithubProject.process_event(event)
    end
  end

  test "pushes_by_deployment/1" do
    %{ok: [%{repository_id: repository_id}, _], error: []} =
      CreateEvent.create_and_process("push", "../support/fixtures/full_flow/push_1.json")

    CreateEvent.create_and_process("push", "../support/fixtures/full_flow/push_2.json")

    %{ok: [%{sha: deployment_1_sha}], error: []} =
      CreateEvent.create_and_process(
        "deployment",
        "../support/fixtures/full_flow/deployment_1.json"
      )

    CreateEvent.create_and_process(
      "deployment_status",
      "../support/fixtures/full_flow/deployment_1_status.json"
    )

    CreateEvent.create_and_process("push", "../support/fixtures/full_flow/push_3.json")

    %{ok: [%{sha: deployment_2_sha}], error: []} =
      CreateEvent.create_and_process(
        "deployment",
        "../support/fixtures/full_flow/deployment_2.json"
      )

    CreateEvent.create_and_process(
      "deployment_status",
      "../support/fixtures/full_flow/deployment_2_status.json"
    )

    CreateEvent.create_and_process("push", "../support/fixtures/full_flow/push_4.json")

    result = GithubProject.pushes_by_deployment(%{repository_id: repository_id})

    assert Map.get(result, deployment_1_sha) |> Enum.count() == 2
    assert Map.get(result, deployment_2_sha) |> Enum.count() == 1
  end

  test "get_events_for/1" do
    {:ok, repo1} = Repository.insert_or_update(%{owner: "owner1", name: "repo1"})
    {:ok, repo2} = Repository.insert_or_update(%{owner: "owner2", name: "repo2"})

    GithubProject.create_event(%{
      event_id: "event1",
      event_type: "push",
      raw_event: %{"repository" => %{"full_name" => "owner1/repo1"}}
    })

    GithubProject.create_event(%{
      event_id: "event2",
      event_type: "push",
      raw_event: %{"repository" => %{"full_name" => "owner2/repo2"}}
    })

    GithubProject.create_event(%{
      event_id: "event3",
      event_type: "push",
      raw_event: %{"repository" => %{"full_name" => "owner2/repo2"}}
    })

    GithubProject.create_event(%{
      event_id: "event4",
      event_type: "push",
      raw_event: %{"repository" => %{"full_name" => "owner1/repo1"}}
    })

    assert ["event1", "event4"] ==
             GithubProject.get_events_for(%{repository_id: repo1.id})
             |> get_event_ids()

    assert ["event2", "event3"] ==
             GithubProject.get_events_for(%{repository_id: Integer.to_string(repo2.id)})
             |> get_event_ids()
  end

  defp get_event_ids(nil), do: flunk("No events found.")

  defp get_event_ids(events) do
    events |> Enum.map(&Map.get(&1, :event_id))
  end
end
