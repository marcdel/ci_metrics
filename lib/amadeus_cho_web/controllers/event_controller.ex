defmodule AmadeusChoWeb.EventController do
  use AmadeusChoWeb, :controller

  def create(conn, event) do
    [event_id] = get_req_header(conn, "x-github-delivery")
    [event_type] = get_req_header(conn, "x-github-event")

    AmadeusCho.Event.create_event(%{event_id: event_id, event_type: event_type, raw: event})

    json(conn, %{success: true, event_id: event_id, event_name: event_type})
  end
end
