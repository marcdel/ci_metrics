defmodule CiMetricsWeb.RepositoryControllerTest do
  import Mox
  use CiMetricsWeb.ConnCase, async: true

  alias CiMetrics.Project.Repository

  setup :verify_on_exit!

  test "GET /repositories/:id", %{conn: conn} do
    repository_id =
      %{"repository" => %{"full_name" => "marcdel/sick_bro"}}
      |> Repository.from_raw_event()
      |> Tuple.to_list()
      |> List.last()
      |> Map.get(:id)
      |> Integer.to_string()

    expect(MockProject, :calculate_lead_time, fn ^repository_id ->
      %CiMetrics.Metrics.TimeUnitMetric{
        days: 0,
        hours: 2,
        minutes: 30,
        seconds: 0,
        weeks: 0
      }
    end)

    expect(MockProject, :daily_lead_time_snapshots, fn ^repository_id ->
      [
        %CiMetrics.Metrics.MetricSnapshot{
          inserted_at: Date.from_iso8601!("2019-10-21"),
          average_lead_time: 6_000_000
        },
        %CiMetrics.Metrics.MetricSnapshot{
          inserted_at: Date.from_iso8601!("2019-10-22"),
          average_lead_time: 86_400
        }
      ]
    end)

    conn = get(conn, "/repositories/" <> repository_id)

    assert response(conn, 200) =~ "Repository: marcdel/sick_bro"
    assert response(conn, 200) =~ "Current Average Lead Time: 2 hours, 30 minutes"
    assert response(conn, 200) =~ "[\"10/21/2019\",\"10/22/2019\"]"
    assert response(conn, 200) =~ "[\"69.42\",\"1.0\"]"
  end
end
