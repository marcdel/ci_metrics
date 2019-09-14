defmodule Plug.WebhookEventValidator do
  import Plug.Conn
  alias CiMetricsWeb.Router.Helpers, as: Routes

  def init(options) do
    options
  end

  def call(conn, secret: secret) do
    event_path = Routes.event_path(conn, :create)

    case conn.request_path do
      ^event_path ->
        {:ok, body, conn} = read_body(conn)
        [signature_in_header] = get_req_header(conn, "x-hub-signature")

        if verify_signature(secret, body, signature_in_header) do
          assign(conn, :raw_event, Jason.decode!(body))
        else
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(403, Jason.encode!(%{success: false, error: "Invalid x-hub-signature"}))
          |> halt()
        end

      _ ->
        conn
    end
  end

  defp verify_signature(nil, _, _) do
    # Don't compare if we're in an environment without a secret
    Plug.Crypto.secure_compare("", "")
  end

  defp verify_signature(secret, body, signature_in_header) do
    secret
    |> generate_signature(body)
    |> Plug.Crypto.secure_compare(signature_in_header)
  end

  defp generate_signature(secret, body) do
    "sha1=" <> (:crypto.hmac(:sha, secret, body) |> Base.encode16(case: :lower))
  end
end
