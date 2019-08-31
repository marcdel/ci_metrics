defmodule AmadeusChoWeb.EventController do
  use AmadeusChoWeb, :controller
  require Logger

  def create(conn, event) do
    [signature] = get_req_header(conn, "x-hub-signature")
    [event_id] = get_req_header(conn, "x-github-delivery")
    [event_name] = get_req_header(conn, "x-github-event")

    %{signature: signature, event_id: event_id, event_name: event_name}
    |> inspect()
    |> Logger.info()

    json(conn, %{success: true, event_id: event_id, event_name: event_name})
  end
end
