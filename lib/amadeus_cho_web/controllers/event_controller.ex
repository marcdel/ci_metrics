defmodule AmadeusChoWeb.EventController do
  use AmadeusChoWeb, :controller
  alias AmadeusCho.Project.Event

  @project Application.get_env(:amadeus_cho, :project, AmadeusCho.Project)

  def create(conn, _) do
    [event_id] = get_req_header(conn, "x-github-delivery")
    [event_type] = get_req_header(conn, "x-github-event")
    event = conn.assigns.raw_event

    request = %{event_id: event_id, event_type: event_type, raw_event: event}

    with {:ok, event} <- @project.create_event(request),
         {:ok, _} <- @project.process_event(event) do
      json(conn, %{success: true})
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        json(conn, %{success: false, error: changeset.errors})
      {:error, _} ->
        json(conn, %{success: false, error: "Error: unable to create or process event."})
    end
  end

  def index(conn, %{"repository_id" => repository_id}) do
    events = @project.get_events_for(%{repository_id: repository_id})
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
