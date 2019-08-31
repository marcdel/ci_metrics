defmodule AmadeusChoWeb.EventControllerTest do
  use AmadeusChoWeb.ConnCase

  test "POST /api/events", %{conn: conn} do
    json_payload =
      "../../support/push.json"
      |> Path.expand(__DIR__)
      |> File.read!()

    result =
      conn
      |> put_req_header("content-type", "application/json")
      |> put_req_header("x-github-delivery", "05b648a1-86cd-4777-bd5c-2e12302d75d3")
      |> put_req_header("x-hub-signature", "sha1=7581fc043b8c47b860b96cfd36fd7078955774e7")
      |> put_req_header("x-github-event", "push")
      |> post("/api/events", json_payload)

    assert json_response(result, 200) == %{
             "success" => true,
             "event_id" => "05b648a1-86cd-4777-bd5c-2e12302d75d3",
             "event_name" => "push"
           }
  end
end
