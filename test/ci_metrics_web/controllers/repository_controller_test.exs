defmodule CiMetricsWeb.RepositoryControllerTest do
  import Mox
  use CiMetricsWeb.ConnCase, async: true

  alias CiMetrics.Project.Repository

  setup :verify_on_exit!

  test "GET /repositories/new shows a form to collect repository information", %{conn: conn} do
    html =
      conn
      |> get("/repositories/new")
      |> html_response(200)

    assert html =~ "Repository"
    assert html =~ "Personal access token"
    assert html =~ "Deployment Strategy"
    assert html =~ Routes.repository_path(conn, :create)
  end

  describe "POST /repositories" do
    test "creates a repository", %{conn: conn} do
      stub(MockHTTPClient, :post, fn _, _, _, [] -> {:ok, %Mojito.Response{status_code: 201}} end)

      conn =
        post(conn, Routes.repository_path(conn, :create), %{
          "repository_name" => "marcdel/ci_metrics",
          "access_token" => "1234509876",
          "deployment_strategy" => :heroku
        })

      assert get_flash(conn, :info) == "Repository set up successfully."

      [repository] = Repository.get_all()
      assert repository.name == "ci_metrics"
      assert repository.owner == "marcdel"
      assert repository.deployment_strategy == :heroku
    end

    test "creates a webhook in the github repository", %{conn: conn} do
      expected_url =
        "https://api.github.com/repos/marcdel/ci_metrics/hooks?access_token=1234509876"

      expect(MockHTTPClient, :post, fn ^expected_url, _, _, [] ->
        {:ok, %Mojito.Response{status_code: 201}}
      end)

      post(conn, Routes.repository_path(conn, :create), %{
        "repository_name" => "marcdel/ci_metrics",
        "access_token" => "1234509876",
        "deployment_strategy" => :heroku
      })
    end

    test "returns the correct message for different kinds of errors", %{conn: conn} do
      request = %{
        "repository_name" => "marcdel/ci_metrics",
        "access_token" => "1234509876",
        "deployment_strategy" => :heroku
      }

      expect(MockHTTPClient, :post, fn _, _, _, [] ->
        {:error, %Mojito.Response{status_code: 422}}
      end)

      conn = post(conn, Routes.repository_path(conn, :create), request)
      assert get_flash(conn, :error) == "Oops! This repository already has a webhook from us."

      expect(MockHTTPClient, :post, fn _, _, _, [] ->
        {:error, %Mojito.Response{status_code: 404}}
      end)

      conn = post(conn, Routes.repository_path(conn, :create), request)
      assert get_flash(conn, :error) == "Oops! We couldn't find that repository."

      expect(MockHTTPClient, :post, fn _, _, _, [] ->
        {:error, %Mojito.Response{status_code: 401}}
      end)

      conn = post(conn, Routes.repository_path(conn, :create), request)

      assert get_flash(conn, :error) ==
               "Oops! The access token you provided doesn't seem to be working."

      expect(MockHTTPClient, :post, fn _, _, _, [] ->
        {:error, %Mojito.Response{status_code: 500}}
      end)

      conn = post(conn, Routes.repository_path(conn, :create), request)

      assert get_flash(conn, :error) ==
               "Oops! We had some trouble creating a webhook for your repository. Please try again."
    end
  end

  test "GET /repositories/:id", %{conn: conn} do
    repository_id =
      %{"repository" => %{"full_name" => "marcdel/sick_bro"}}
      |> Repository.from_raw_event()
      |> Tuple.to_list()
      |> List.last()
      |> Map.get(:id)
      |> Integer.to_string()

    expect(MockProject, :calculate_lead_time, fn ^repository_id ->
      %CiMetrics.Metrics.TimeUnitMetric{
        days: 0,
        hours: 2,
        minutes: 30,
        seconds: 0,
        weeks: 0
      }
    end)

    expect(MockProject, :daily_lead_time_snapshots, fn ^repository_id ->
      [
        %CiMetrics.Metrics.MetricSnapshot{
          inserted_at: Date.from_iso8601!("2019-10-21"),
          average_lead_time: 6_000_000
        },
        %CiMetrics.Metrics.MetricSnapshot{
          inserted_at: Date.from_iso8601!("2019-10-22"),
          average_lead_time: 86_400
        }
      ]
    end)

    conn = get(conn, "/repositories/" <> repository_id)

    assert response(conn, 200) =~ "Repository: marcdel/sick_bro"
    assert response(conn, 200) =~ "Current Average Lead Time: 2 hours, 30 minutes"
    assert response(conn, 200) =~ "[\"10/21/2019\",\"10/22/2019\"]"
    assert response(conn, 200) =~ "[\"1666.67\",\"24.0\"]"
  end
end
