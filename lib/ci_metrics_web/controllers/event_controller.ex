defmodule CiMetricsWeb.EventController do
  use CiMetricsWeb, :controller
  alias CiMetrics.GithubProject
  alias CiMetrics.Events.Event

  @project Application.get_env(:ci_metrics, :project, GithubProject)

  def create(conn, _) do
    [event_id] = get_req_header(conn, "x-github-delivery")
    [event_type] = get_req_header(conn, "x-github-event")
    event = conn.assigns.raw_event

    request = %{event_id: event_id, event_type: event_type, raw_event: event}

    with {:ok, event} <- @project.create_event(request),
         %{ok: _, error: []} <- @project.process_event(event) do
      json(conn, %{success: true})
    else
      {:error, %Ecto.Changeset{data: %Event{}}} ->
        conn
        |> put_status(400)
        |> json(%{success: false, error: "There was a problem creating this event"})

      %{ok: [], error: _} ->
        conn
        |> put_status(400)
        |> json(%{
          success: false,
          error: "Event successfully saved, but all processing failed"
        })

      %{ok: _, error: _} ->
        conn
        |> put_status(400)
        |> json(%{
          success: false,
          error: "Event successfully saved, but some processing failed"
        })

      {:error, _} ->
        conn
        |> put_status(500)
        |> json(%{
          success: false,
          error: "There was a problem creating or processing this event"
        })
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
