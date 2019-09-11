defmodule AmadeusChoWeb.EventControllerTest do
  import Mox
  use AmadeusChoWeb.ConnCase, async: true

  alias AmadeusCho.Project
  alias AmadeusCho.Project.{Event, Repository}

  setup :verify_on_exit!

  test "POST /api/events", %{conn: conn} do
    json_payload =
      "../../support/push.json"
      |> Path.expand(__DIR__)
      |> File.read!()

    create_event_request = %{event_id: "05b648a1-86cd-4777-bd5c-2e12302d75d3", event_type: "push"}
    created_event = %Event{}

    expect(MockProject, :create_event, fn create_event_request -> {:ok, created_event} end)
    expect(MockProject, :process_event, fn created_event -> {:ok, created_event} end)

    conn =
      conn
      |> put_req_header("content-type", "application/json")
      |> put_req_header("x-hub-signature", "not checked on this context")
      |> put_req_header("x-github-delivery", "05b648a1-86cd-4777-bd5c-2e12302d75d3")
      |> put_req_header("x-github-event", "push")
      |> post("/api/events", json_payload)

    assert json_response(conn, 200) == %{"success" => true}
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
    expect(MockProject, :get_events_for, fn %{repository_id: "12345"} ->
      [
        %Event{id: 1, event_id: "event1", repository: %Repository{owner: "owner", name: "name"}},
        %Event{id: 2, event_id: "event2", repository: %Repository{owner: "owner", name: "name"}}
      ]
    end)

    conn = get(conn, "/events?repository_id=12345")

    assert response(conn, 200) =~ "event1"
    assert response(conn, 200) =~ "event2"
    assert response(conn, 200) =~ "owner/name"
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
