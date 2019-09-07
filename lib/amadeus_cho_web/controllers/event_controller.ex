defmodule AmadeusChoWeb.EventController do
  use AmadeusChoWeb, :controller
  alias AmadeusCho.Project
  alias AmadeusCho.Project.Event

  def create(conn, event) do
    [event_id] = get_req_header(conn, "x-github-delivery")
    [event_type] = get_req_header(conn, "x-github-event")

    case verify_signature(conn, event) do
      true ->
        Project.create_event(%{
          event_id: event_id,
          event_type: event_type,
          raw_event: event
        })

        json(conn, %{success: true})

      false ->
        conn
        |> put_status(403)
        |> json(%{success: false, error: "Invalid signature"})
    end
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

  defp verify_signature(conn, event) do
    github_secret = Application.get_env(:amadeus_cho, :github_secret)
    [signature_in_header] = get_req_header(conn, "x-hub-signature")
    json_payload = Jason.encode!(event)

    verify_signature(json_payload, github_secret, signature_in_header)
  end

  defp verify_signature(_, nil, _) do
    # Don't compare if we're in an environment without a secret
    Plug.Crypto.secure_compare("", "")
  end

  defp verify_signature(json_payload, secret, signature_in_header) do
    signature =
      "sha1=" <> (:crypto.hmac(:sha, secret, json_payload) |> Base.encode16(case: :lower))

    Plug.Crypto.secure_compare(signature, signature_in_header)
  end
end
