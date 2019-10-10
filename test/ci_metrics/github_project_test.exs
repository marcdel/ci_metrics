defmodule CiMetrics.GithubProjectTest do
  use CiMetrics.DataCase, async: true

  alias CiMetrics.Events.{Event, Deployment, DeploymentStatus}
  alias CiMetrics.GithubProject
  alias CiMetrics.Metrics.TimeUnitMetric
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
      event = CreateEvent.create("push")
      %{ok: [%Commit{}], error: []} = GithubProject.process_event(event)

      event = CreateEvent.create("deployment")
      %{ok: [%Deployment{}], error: []} = GithubProject.process_event(event)

      event = CreateEvent.create("deployment_status")
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

  describe "pushes_by_deployment/1" do
    test "associates pushes with the following deploy" do
      CreateEvent.create_and_process("push", %{"before" => "", "after" => "1"})
      CreateEvent.create_and_process("push", %{"before" => "1", "after" => "2"})
      CreateEvent.create_and_process("push", %{"before" => "3", "after" => "4"})
      CreateEvent.create_and_process("deployment", %{"deployment" => %{"id" => 1, "sha" => "4"}})

      CreateEvent.create_and_process("deployment_status", %{
        "deployment_status" => %{"id" => 1},
        "deployment" => %{"id" => 1, "sha" => "4"}
      })

      CreateEvent.create_and_process("push", %{"before" => "4", "after" => "5"})
      CreateEvent.create_and_process("push", %{"before" => "5", "after" => "6"})
      CreateEvent.create_and_process("push", %{"before" => "6", "after" => "7"})
      CreateEvent.create_and_process("deployment", %{"deployment" => %{"id" => 2, "sha" => "7"}})

      CreateEvent.create_and_process("deployment_status", %{
        "deployment_status" => %{"id" => 2},
        "deployment" => %{"id" => 2, "sha" => "7"}
      })

      [%{id: repository_id}] = Repository.get_all()

      result = GithubProject.pushes_by_deployment(repository_id)
      assert Map.get(result, "4", []) |> Enum.count() == 3
      assert Map.get(result, "7", []) |> Enum.count() == 3
    end

    test "handle gaps in push events" do
      CreateEvent.create_and_process("push", %{"before" => "", "after" => "1"})
      CreateEvent.create_and_process("push", %{"before" => "1", "after" => "2"})
      CreateEvent.create_and_process("push", %{"before" => "3", "after" => "4"})
      CreateEvent.create_and_process("deployment", %{"deployment" => %{"sha" => "4"}})
      CreateEvent.create_and_process("deployment_status", %{"deployment" => %{"sha" => "4"}})

      [%{id: repository_id}] = Repository.get_all()

      result = GithubProject.pushes_by_deployment(repository_id)
      assert Map.get(result, "4", []) |> Enum.count() == 3
    end

    test "handle first push" do
      CreateEvent.create_and_process("push", %{"before" => "", "after" => "1"})
      CreateEvent.create_and_process("deployment", %{"deployment" => %{"sha" => "1"}})
      CreateEvent.create_and_process("deployment_status", %{"deployment" => %{"sha" => "1"}})

      [%{id: repository_id}] = Repository.get_all()

      result = GithubProject.pushes_by_deployment(repository_id)
      assert Map.get(result, "1", []) |> Enum.count() == 1
    end
  end

  describe "calculate_lead_time/1" do
    test "lead time is the time from commit to successful deployment" do
      CreateEvent.create_and_process("push", %{
        "before" => "",
        "after" => "1",
        "commits" => [
          %{"id" => "1", "timestamp" => "2019-01-01 10:00:00Z"}
        ]
      })

      CreateEvent.create_and_process("deployment", %{
        "deployment" => %{
          "id" => 1,
          "sha" => "1",
          "created_at" => "2019-01-01 11:00:00Z"
        }
      })

      CreateEvent.create_and_process("deployment_status", %{
        "deployment_status" => %{
          "id" => 1,
          "state" => "pending",
          "created_at" => "2019-01-01 11:30:00Z"
        },
        "deployment" => %{"id" => 1, "sha" => "1"}
      })

      CreateEvent.create_and_process("deployment_status", %{
        "deployment_status" => %{
          "id" => 2,
          "state" => "success",
          "created_at" => "2019-01-01 12:00:00Z"
        },
        "deployment" => %{"id" => 1, "sha" => "1"}
      })

      [%{id: repository_id}] = Repository.get_all()

      lead_time = GithubProject.calculate_lead_time(repository_id)

      assert lead_time == %CiMetrics.Metrics.TimeUnitMetric{
               days: 0,
               hours: 2,
               minutes: 0,
               seconds: 0,
               weeks: 0
             }
    end

    test "total lead time is the average of lead time of all commits across all deployments" do
      CreateEvent.create_and_process("push", %{
        "before" => "",
        "after" => "2",
        "commits" => [
          %{"id" => "1", "timestamp" => "2019-01-01 10:00:00Z"},
          %{"id" => "2", "timestamp" => "2019-01-01 11:00:00Z"}
        ]
      })

      CreateEvent.create_and_process("deployment", %{
        "deployment" => %{
          "id" => 1,
          "sha" => "2",
          "created_at" => "2019-01-01 11:00:00Z"
        }
      })

      CreateEvent.create_and_process("deployment_status", %{
        "deployment_status" => %{
          "id" => 1,
          "state" => "success",
          "created_at" => "2019-01-01 12:00:00Z"
        },
        "deployment" => %{"id" => 1, "sha" => "2"}
      })

      CreateEvent.create_and_process("push", %{
        "before" => "",
        "after" => "4",
        "commits" => [
          %{"id" => "3", "timestamp" => "2019-01-01 13:00:00Z"},
          %{"id" => "4", "timestamp" => "2019-01-01 14:00:00Z"}
        ]
      })

      CreateEvent.create_and_process("deployment", %{
        "deployment" => %{
          "id" => 2,
          "sha" => "4",
          "created_at" => "2019-01-01 14:00:00Z"
        }
      })

      CreateEvent.create_and_process("deployment_status", %{
        "deployment_status" => %{
          "id" => 2,
          "state" => "success",
          "created_at" => "2019-01-01 15:00:00Z"
        },
        "deployment" => %{"id" => 2, "sha" => "4"}
      })

      [%{id: repository_id}] = Repository.get_all()

      lead_time = GithubProject.calculate_lead_time(repository_id)

      assert lead_time == %CiMetrics.Metrics.TimeUnitMetric{
               days: 0,
               hours: 1,
               minutes: 30,
               seconds: 0,
               weeks: 0
             }
    end

    test "returns 0 when there are no deployments" do
      assert GithubProject.calculate_lead_time(666) == %CiMetrics.Metrics.TimeUnitMetric{
               days: 0,
               hours: 0,
               minutes: 0,
               seconds: 0,
               weeks: 0
             }
    end

    test "does not count deployments with no pushes" do
      CreateEvent.create_and_process("deployment", %{
        "deployment" => %{
          "id" => 1,
          "sha" => "1",
          "created_at" => "2019-01-01 14:00:00Z"
        }
      })

      CreateEvent.create_and_process("deployment_status", %{
        "deployment_status" => %{
          "id" => 1,
          "state" => "success",
          "created_at" => "2019-01-01 15:00:00Z"
        },
        "deployment" => %{"id" => 1, "sha" => "1"}
      })

      [%{id: repository_id}] = Repository.get_all()

      lead_time = GithubProject.calculate_lead_time(repository_id)

      assert lead_time == %CiMetrics.Metrics.TimeUnitMetric{
               days: 0,
               hours: 0,
               minutes: 0,
               seconds: 0,
               weeks: 0
             }
    end

    test "does not count commits in unsuccessful deployments" do
      CreateEvent.create_and_process("push", %{
        "before" => "",
        "after" => "1",
        "commits" => [
          %{"id" => "1", "timestamp" => "2019-01-01 10:00:00Z"}
        ]
      })

      CreateEvent.create_and_process("deployment", %{
        "deployment" => %{
          "id" => 1,
          "sha" => "1",
          "created_at" => "2019-01-01 11:00:00Z"
        }
      })

      CreateEvent.create_and_process("deployment_status", %{
        "deployment_status" => %{
          "id" => 1,
          "state" => "pending",
          "created_at" => "2019-01-01 11:30:00Z"
        },
        "deployment" => %{"id" => 1, "sha" => "1"}
      })

      [%{id: repository_id}] = Repository.get_all()

      lead_time = GithubProject.calculate_lead_time(repository_id)

      assert lead_time == %TimeUnitMetric{
               days: 0,
               hours: 0,
               minutes: 0,
               seconds: 0,
               weeks: 0
             }
    end

    test "does not count commits after the latest deployment" do
      CreateEvent.create_and_process("push", %{
        "before" => "",
        "after" => "1",
        "commits" => [
          %{"id" => "1", "timestamp" => "2019-01-01 10:00:00Z"}
        ]
      })

      CreateEvent.create_and_process("deployment", %{
        "deployment" => %{
          "id" => 1,
          "sha" => "1",
          "created_at" => "2019-01-01 11:00:00Z"
        }
      })

      CreateEvent.create_and_process("deployment_status", %{
        "deployment_status" => %{
          "id" => 1,
          "state" => "success",
          "created_at" => "2019-01-01 12:00:00Z"
        },
        "deployment" => %{"id" => 1, "sha" => "1"}
      })

      CreateEvent.create_and_process("push", %{
        "before" => "",
        "after" => "3",
        "commits" => [
          %{"id" => "2", "timestamp" => "2019-01-01 13:00:00Z"},
          %{"id" => "3", "timestamp" => "2019-01-01 14:00:00Z"}
        ]
      })

      [%{id: repository_id}] = Repository.get_all()

      lead_time = GithubProject.calculate_lead_time(repository_id)

      assert lead_time == %CiMetrics.Metrics.TimeUnitMetric{
               days: 0,
               hours: 2,
               minutes: 0,
               seconds: 0,
               weeks: 0
             }
    end
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
