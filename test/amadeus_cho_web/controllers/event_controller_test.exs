defmodule AmadeusChoWeb.EventControllerTest do
  use AmadeusChoWeb.ConnCase, async: true
  alias AmadeusCho.Event

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
      Event.create_event(%{
        event_id: "05b648a1-86cd-4777-bd5c-2e12302d75d3",
        event_type: "push",
        raw: %{"commits" => []}
      })

    [event] = Event.get_all()
    assert event.event_id == "05b648a1-86cd-4777-bd5c-2e12302d75d3"
    assert event.event_type == "push"

    conn = get(conn, "/events")

    assert response(conn, 200) =~ "05b648a1-86cd-4777-bd5c-2e12302d75d3"
  end

  test "GET /events/:id", %{conn: conn} do
    Event.create_event(%{
      event_id: "05b648a1-86cd-4777-bd5c-2e12302d75d3",
      event_type: "push",
      raw: %{"commits" => [%{"id" => "cbc47eabe663e87be4bd8d385abd99c54b53ac00"}]}
    })

    [event] = Event.get_all()

    conn = get(conn, "/events/#{event.id}")

    assert response(conn, 200) =~ "cbc47eabe663e87be4bd8d385abd99c54b53ac00"
  end
end
