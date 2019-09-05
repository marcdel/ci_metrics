defmodule AmadeusChoWeb.WebhookControllerTest do
  use AmadeusChoWeb.ConnCase, async: true
  import Mox

  setup :verify_on_exit!

  test "GET /webhooks/new", %{conn: conn} do
    html =
      conn
      |> get("/webhooks/new")
      |> html_response(200)

    assert html =~ "Repository"
    assert html =~ "Personal access token"
  end

  test "POST /webhooks", %{conn: conn} do
    expected_url =
      "https://api.github.com/repos/marcdel/amadeus_cho/hooks?access_token=1234509876"

    expect(MockHTTPClient, :post, fn ^expected_url, _, _, [] ->
      {:ok, %Mojito.Response{status_code: 201}}
    end)

    conn =
      post(conn, Routes.webhook_path(conn, :create), %{
        "repository_name" => "marcdel/amadeus_cho",
        "access_token" => "1234509876"
      })

    assert get_flash(conn, :info) == "Webhook created."
  end

  test "POST /webhooks with github error", %{conn: conn} do
    expect(MockHTTPClient, :post, fn _, _, _, [] ->
      {:error, %Mojito.Response{status_code: 500}}
    end)

    conn =
      post(conn, Routes.webhook_path(conn, :create), %{
        "repository_name" => "marcdel/amadeus_cho",
        "access_token" => "1234509876"
      })

    assert get_flash(conn, :error) == "Oops! We had some trouble creating your webhook."
  end
end
