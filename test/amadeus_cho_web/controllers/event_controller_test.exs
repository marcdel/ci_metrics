defmodule AmadeusChoWeb.EventControllerTest do
  use AmadeusChoWeb.ConnCase, async: true
  alias AmadeusCho.{Event, Project, Repository}

  test "POST /api/events", %{conn: conn} do
    json_payload =
      "../../support/push.json"
      |> Path.expand(__DIR__)
      |> File.read!()

    conn =
      conn
      |> put_req_header("content-type", "application/json")
      |> put_req_header("x-hub-signature", "sha1=7581fc043b8c47b860b96cfd36fd7078955774e7")
      |> put_req_header("x-github-delivery", "05b648a1-86cd-4777-bd5c-2e12302d75d3")
      |> put_req_header("x-github-event", "push")
      |> post("/api/events", json_payload)

    assert json_response(conn, 200)

    [event] = Event.get_all()
    assert event.event_id == "05b648a1-86cd-4777-bd5c-2e12302d75d3"
    assert event.event_type == "push"
    assert event.raw["sender"]["login"] == "marcdel"
  end

  test "GET /events", %{conn: conn} do
    {:ok, _} =
      Project.create_event(%{
        event_id: "05b648a1-86cd-4777-bd5c-2e12302d75d3",
        event_type: "push",
        raw_event: %{"repository" => %{"full_name" => "marcdel/amadeus_cho_test"}}
      })

    [event] = Event.get_all()
    assert event.event_id == "05b648a1-86cd-4777-bd5c-2e12302d75d3"
    assert event.event_type == "push"

    conn = get(conn, "/events")

    assert response(conn, 200) =~ "05b648a1-86cd-4777-bd5c-2e12302d75d3"
    assert response(conn, 200) =~ "marcdel/amadeus_cho_test"
  end

  test "GET /events?repository_id=:id", %{conn: conn} do
    {:ok, _} =
      Project.create_event(%{
        event_id: "event1",
        event_type: "push",
        raw_event: %{"repository" => %{"full_name" => "marcdel/repo1"}}
      })

    {:ok, _} =
      Project.create_event(%{
        event_id: "event2",
        event_type: "push",
        raw_event: %{"repository" => %{"full_name" => "marcdel/repo2"}}
      })

    {:ok, _} =
      Project.create_event(%{
        event_id: "event3",
        event_type: "push",
        raw_event: %{"repository" => %{"full_name" => "marcdel/repo1"}}
      })

    repository = Repository.get_by(%{owner: "marcdel", name: "repo1"})

    conn = get(conn, "/events?repository_id=#{repository.id}")

    assert response(conn, 200) =~ "event1"
    refute response(conn, 200) =~ "event2"
    assert response(conn, 200) =~ "event3"
  end

  test "GET /events/:id", %{conn: conn} do
    Project.create_event(%{
      event_id: "05b648a1-86cd-4777-bd5c-2e12302d75d3",
      event_type: "push",
      raw_event: %{
        "repository" => %{"full_name" => "marcdel/amadeus_cho_test"},
        "commits" => [%{"id" => "cbc47eabe663e87be4bd8d385abd99c54b53ac00"}]
      }
    })

    [event] = Event.get_all()

    conn = get(conn, "/events/#{event.id}")

    assert response(conn, 200) =~ "cbc47eabe663e87be4bd8d385abd99c54b53ac00"
    assert response(conn, 200) =~ "marcdel/amadeus_cho_test"
  end
end
