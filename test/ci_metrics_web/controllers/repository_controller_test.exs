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

    expect(MockProject, :calculate_lead_time, fn ^repository_id -> {120, :minutes} end)

    conn = get(conn, "/repositories/" <> repository_id)

    assert response(conn, 200) =~ "Repository: marcdel/sick_bro"
    assert response(conn, 200) =~ "Average Lead Time: 120 minutes"
  end
end
