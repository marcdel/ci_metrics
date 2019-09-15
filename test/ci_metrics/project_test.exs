defmodule CiMetrics.ProjectTest do
  use CiMetrics.DataCase, async: true
  alias CiMetrics.Project
  alias CiMetrics.Project.{Commit, Event, Repository}

  describe "create_event/3" do
    test "creates an event with the id, type and raw event" do
      event_id = "05b648a1-86cd-4777-bd5c-2e12302d75d3"
      event_type = "push"

      raw_event =
        "../support/push.json"
        |> Path.expand(__DIR__)
        |> File.read!()
        |> Jason.decode!()

      Project.create_event(%{
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

      Project.create_event(%{
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
               Project.create_event(%{
                 event_id: "same-event-id",
                 event_type: event_type,
                 raw_event: raw_event
               })

      assert {:ok, ^event} =
               Project.create_event(%{
                 event_id: "same-event-id",
                 event_type: event_type,
                 raw_event: raw_event
               })

      assert Event.get_all() |> Enum.count() == 1
    end
  end

  describe "process_event/1" do
    test "push event creates a commit record for each commit in the push" do
      event_id = "05b648a1-86cd-4777-bd5c-2e12302d75d3"
      event_type = "push"

      raw_event =
        "../support/fixtures/multi_push.json"
        |> Path.expand(__DIR__)
        |> File.read!()
        |> Jason.decode!()

      {:ok, event} =
        Project.create_event(%{
          event_id: event_id,
          event_type: event_type,
          raw_event: raw_event
        })

      %{ok: [commit1, commit2], error: []} = Project.process_event(event)

      assert commit1.sha == "8dfe6b686e0bf1a2860b03f6d2e4567002d3fdda"
      assert commit1.branch == "master"
      assert DateTime.to_string(commit1.committed_at) == "2019-09-06 03:26:16Z"
      assert commit1.event_id != nil
      assert commit1.repository_id != nil

      assert commit2.sha == "b5ec9bbdd6a75451e02f9a464fe2418d9eaead81"
      assert commit2.branch == "master"
      assert DateTime.to_string(commit2.committed_at) == "2019-09-06 03:26:10Z"
      assert commit2.event_id == commit1.event_id
      assert commit2.repository_id == commit1.repository_id
    end

    test "cannot create the same commit twice" do
      event_id = "05b648a1-86cd-4777-bd5c-2e12302d75d3"
      event_type = "push"

      raw_event =
        "../support/fixtures/multi_push.json"
        |> Path.expand(__DIR__)
        |> File.read!()
        |> Jason.decode!()

      {:ok, event} =
        Project.create_event(%{
          event_id: event_id,
          event_type: event_type,
          raw_event: raw_event
        })

      assert %{ok: [commit1, commit2], error: []} = Project.process_event(event)
      assert %{ok: [^commit1, ^commit2], error: []} = Project.process_event(event)
      assert Commit.get_all() |> Enum.count() == 2
    end

    test "can process deployment events" do
      event_id = "05b648a1-86cd-4777-bd5c-2e12302d75d3"
      event_type = "deployment"

      raw_event =
        "../support/fixtures/deployment.json"
        |> Path.expand(__DIR__)
        |> File.read!()
        |> Jason.decode!()

      {:ok, event} =
        Project.create_event(%{
          event_id: event_id,
          event_type: event_type,
          raw_event: raw_event
        })

      %{ok: [deployment], error: []} = Project.process_event(event)

      assert deployment.deployment_id == 167_780_832
      assert deployment.sha == "eb475e393647070a6b0273b9d284dbc535bb4d7a"
      assert DateTime.to_string(deployment.started_at) == "2019-09-08 21:55:48Z"

      assert deployment.event_id != nil
      assert deployment.repository_id != nil
    end

    test "handles unknown event types" do
      event_id = "05b648a1-86cd-4777-bd5c-2e12302d75d3"
      event_type = "unknown_type"

      raw_event =
        "../support/fixtures/unknown_event.json"
        |> Path.expand(__DIR__)
        |> File.read!()
        |> Jason.decode!()

      {:ok, event} =
        Project.create_event(%{
          event_id: event_id,
          event_type: event_type,
          raw_event: raw_event
        })

      assert %{ok: [], error: []} = Project.process_event(event)
    end
  end

  test "get_events_for/1" do
    {:ok, repo1} = Repository.insert_or_update(%{owner: "owner1", name: "repo1"})
    {:ok, repo2} = Repository.insert_or_update(%{owner: "owner2", name: "repo2"})

    Project.create_event(%{
      event_id: "event1",
      event_type: "push",
      raw_event: %{"repository" => %{"full_name" => "owner1/repo1"}}
    })

    Project.create_event(%{
      event_id: "event2",
      event_type: "push",
      raw_event: %{"repository" => %{"full_name" => "owner2/repo2"}}
    })

    Project.create_event(%{
      event_id: "event3",
      event_type: "push",
      raw_event: %{"repository" => %{"full_name" => "owner2/repo2"}}
    })

    Project.create_event(%{
      event_id: "event4",
      event_type: "push",
      raw_event: %{"repository" => %{"full_name" => "owner1/repo1"}}
    })

    assert ["event1", "event4"] ==
             Project.get_events_for(%{repository_id: repo1.id}) |> get_event_ids()

    assert ["event2", "event3"] ==
             Project.get_events_for(%{repository_id: Integer.to_string(repo2.id)})
             |> get_event_ids()
  end

  defp get_event_ids(nil), do: flunk("No events found.")

  defp get_event_ids(events) do
    events |> Enum.map(&Map.get(&1, :event_id))
  end
end
