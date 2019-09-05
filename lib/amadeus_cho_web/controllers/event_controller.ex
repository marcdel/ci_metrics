defmodule AmadeusChoWeb.EventController do
  use AmadeusChoWeb, :controller

  def create(conn, event) do
    [event_id] = get_req_header(conn, "x-github-delivery")
    [event_type] = get_req_header(conn, "x-github-event")

    AmadeusCho.Organizations.create_event(%{
      event_id: event_id,
      event_type: event_type,
      raw_event: event
    })

    json(conn, %{success: true, event_id: event_id, event_name: event_type})
  end

  def index(conn, _params) do
    events = AmadeusCho.Event.get_all()
    render(conn, "index.html", events: events)
  end

  def show(conn, params) do
    event = AmadeusCho.Event.get_by(id: params["id"])
    render(conn, "show.html", event: event)
  end
end
