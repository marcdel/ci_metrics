defmodule CiMetricsWeb.WebhookControllerTest do
  use CiMetricsWeb.ConnCase, async: true
  import Mox

  alias CiMetrics.Project.Repository

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
    expected_url = "https://api.github.com/repos/marcdel/ci_metrics/hooks?access_token=1234509876"

    expect(MockHTTPClient, :post, fn ^expected_url, _, _, [] ->
      {:ok, %Mojito.Response{status_code: 201}}
    end)

    conn =
      post(conn, Routes.webhook_path(conn, :create), %{
        "repository_name" => "marcdel/ci_metrics",
        "access_token" => "1234509876"
      })

    assert get_flash(conn, :info) == "Webhook created."

    [repository] = Repository.get_all()
    assert repository.name == "ci_metrics"
    assert repository.owner == "marcdel"
  end

  test "POST /webhooks with github error", %{conn: conn} do
    expect(MockHTTPClient, :post, fn _, _, _, [] ->
      {:error, %Mojito.Response{status_code: 500}}
    end)

    conn =
      post(conn, Routes.webhook_path(conn, :create), %{
        "repository_name" => "marcdel/ci_metrics",
        "access_token" => "1234509876"
      })

    assert get_flash(conn, :error) == "Oops! We had some trouble creating your webhook."
  end
end
