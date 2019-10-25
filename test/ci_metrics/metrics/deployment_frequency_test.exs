defmodule CiMetrics.Metrics.DeploymentFrequencyTest do
  use CiMetrics.DataCase, async: true

  alias CiMetrics.Metrics.{DeploymentFrequency, TimeUnitMetric}
  alias CiMetrics.Project.Repository

  describe "calculate/1" do
    test "deployment frequency is the average time between successful deploys" do
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

      CreateEvent.create_and_process("deployment", %{
        "deployment" => %{
          "id" => 2,
          "sha" => "2",
          "created_at" => "2019-01-01 13:00:00Z"
        }
      })

      CreateEvent.create_and_process("deployment_status", %{
        "deployment_status" => %{
          "id" => 2,
          "state" => "success",
          "created_at" => "2019-01-01 14:00:00Z"
        },
        "deployment" => %{"id" => 2, "sha" => "2"}
      })

      [%{id: repository_id}] = Repository.get_all()

      lead_time = DeploymentFrequency.calculate(repository_id)

      assert lead_time == %TimeUnitMetric{
               days: 0,
               hours: 2,
               minutes: 0,
               seconds: 0,
               weeks: 0
             }
    end
  end
end
