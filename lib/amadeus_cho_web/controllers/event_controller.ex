defmodule AmadeusChoWeb.EventController do
  use AmadeusChoWeb, :controller
  alias AmadeusCho.Project
  alias AmadeusCho.Project.Event

  def create(conn, event) do
    [event_id] = get_req_header(conn, "x-github-delivery")
    [event_type] = get_req_header(conn, "x-github-event")

    Project.create_event(%{
      event_id: event_id,
      event_type: event_type,
      raw_event: event
    })

    json(conn, %{success: true, event_id: event_id, event_name: event_type})
  end

  def index(conn, %{"repository_id" => repository_id}) do
    events = Project.get_events_for(%{repository_id: repository_id})
    render(conn, "index.html", events: events)
  end

  def index(conn, _) do
    events = Event.get_all()
    render(conn, "index.html", events: events)
  end

  def show(conn, params) do
    event = Event.get_by(id: params["id"])
    render(conn, "show.html", event: event)
  end
end
