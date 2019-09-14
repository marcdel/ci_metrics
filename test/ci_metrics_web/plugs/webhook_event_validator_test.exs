defmodule Plug.WebhookEventValidatorTest do
  use ExUnit.Case, async: true
  use Plug.Test

  defmodule FakePlug do
    use Plug.Builder

    plug Plug.WebhookEventValidator, secret: "secret"
    plug :next_plug

    def next_plug(conn, _opts) do
      Process.put(:next_plug_called, true)
      conn |> send_resp(200, "OK") |> halt()
    end
  end

  test "when verification fails, returns a 403" do
    conn =
      conn(:get, "/api/events", "{\"hello\":\"world\"}")
      |> put_req_header("x-hub-signature", "sha1=wrong_hexdigest")
      |> FakePlug.call([])

    assert conn.status == 403
    assert conn.resp_body == "{\"error\":\"Invalid x-hub-signature\",\"success\":false}"
    refute Process.get(:next_plug_called)
  end

  test "when payload is verified, returns a 200" do
    payload = %{"hello" => "world"}
    {:ok, encoded_payload} = Jason.encode(payload)

    hexdigest =
      "sha1=" <> (:crypto.hmac(:sha, "secret", encoded_payload) |> Base.encode16(case: :lower))

    conn =
      conn(:get, "/api/events", encoded_payload)
      |> put_req_header("x-hub-signature", hexdigest)
      |> FakePlug.call([])

    assert conn.status == 200
    assert Process.get(:next_plug_called)
    assert conn.assigns.raw_event == payload
  end

  test "when path does not match, skips this plug and proceeds to next one" do
    conn =
      conn(:get, "/hello")
      |> put_req_header("x-hub-signature", "sha1=wrong_hexdigest")
      |> FakePlug.call([])

    assert conn.status == 200
    assert Process.get(:next_plug_called)
  end
end
