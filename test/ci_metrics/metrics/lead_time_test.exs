defmodule CiMetrics.Metrics.LeadTimeTest do
  use CiMetrics.DataCase, async: true

  alias CiMetrics.Metrics.{LeadTime, TimeUnitMetric}
  alias CiMetrics.Project.Repository

  describe "all_time_average/1" do
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

      lead_time = LeadTime.all_time_average(repository_id)

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

      lead_time = LeadTime.all_time_average(repository_id)

      assert lead_time == %CiMetrics.Metrics.TimeUnitMetric{
               days: 0,
               hours: 1,
               minutes: 30,
               seconds: 0,
               weeks: 0
             }
    end

    test "returns 0 when there are no deployments" do
      assert LeadTime.all_time_average(666) == %CiMetrics.Metrics.TimeUnitMetric{
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

      lead_time = LeadTime.all_time_average(repository_id)

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

      lead_time = LeadTime.all_time_average(repository_id)

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

      lead_time = LeadTime.all_time_average(repository_id)

      assert lead_time == %CiMetrics.Metrics.TimeUnitMetric{
               days: 0,
               hours: 2,
               minutes: 0,
               seconds: 0,
               weeks: 0
             }
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

      result = LeadTime.pushes_by_deployment(repository_id)
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

      result = LeadTime.pushes_by_deployment(repository_id)
      assert Map.get(result, "4", []) |> Enum.count() == 3
    end

    test "handle first push" do
      CreateEvent.create_and_process("push", %{"before" => "", "after" => "1"})
      CreateEvent.create_and_process("deployment", %{"deployment" => %{"sha" => "1"}})
      CreateEvent.create_and_process("deployment_status", %{"deployment" => %{"sha" => "1"}})

      [%{id: repository_id}] = Repository.get_all()

      result = LeadTime.pushes_by_deployment(repository_id)
      assert Map.get(result, "1", []) |> Enum.count() == 1
    end
  end
end
