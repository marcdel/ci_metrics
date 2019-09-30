defmodule CiMetricsWeb.EventControllerTest do
  import Mox
  use CiMetricsWeb.ConnCase, async: true

  alias CiMetrics.Events.Event
  alias CiMetrics.GithubProject
  alias CiMetrics.Project.{Commit, Repository}

  setup :verify_on_exit!
  @json_payload "../../support/push.json" |> Path.expand(__DIR__) |> File.read!()

  test "POST /api/events", %{conn: conn} do
    expect(MockProject, :create_event, fn _ -> {:ok, %Event{}} end)

    expect(MockProject, :process_event, fn _ ->
      %{ok: [%Commit{}, %Commit{}], error: []}
    end)

    conn =
      conn
      |> put_req_header("content-type", "application/json")
      |> put_req_header("x-hub-signature", "not checked on this context")
      |> put_req_header("x-github-delivery", "05b648a1-86cd-4777-bd5c-2e12302d75d3")
      |> put_req_header("x-github-event", "push")
      |> post("/api/events", @json_payload)

    assert %{"success" => true} = json_response(conn, 200)
  end

  test "POST /api/events when an error occurs creating an event", %{conn: conn} do
    expect(
      MockProject,
      :create_event,
      fn _ ->
        {
          :error,
          %Ecto.Changeset{
            action: :insert,
            changes: %{
              event_id: "48098122-d44b-11e9-824f-7b9a7c1e06b3",
              event_type: "push",
              raw: %{},
              repository_id: 3
            },
            types: [],
            errors: [
              event_id:
                {"has already been taken",
                 [constraint: :unique, constraint_name: "events_event_id_index"]}
            ],
            data: %Event{},
            valid?: false
          }
        }
      end
    )

    conn =
      conn
      |> put_req_header("content-type", "application/json")
      |> put_req_header("x-hub-signature", "not checked on this context")
      |> put_req_header("x-github-delivery", "05b648a1-86cd-4777-bd5c-2e12302d75d3")
      |> put_req_header("x-github-event", "push")
      |> post("/api/events", @json_payload)

    assert json_response(conn, 400) == %{
             "success" => false,
             "error" => "There was a problem creating this event"
           }
  end

  test "POST /api/events when an error occurs processing an event", %{conn: conn} do
    commit_error = %Ecto.Changeset{
      action: :insert,
      changes: %{
        branch: "master",
        committed_at: ~U[2019-09-06 03:26:10Z],
        event_id: 4782,
        repository_id: 3296,
        sha: "b5ec9bbdd6a75451e02f9a464fe2418d9eaead81"
      },
      types: [],
      errors: [
        sha:
          {"has already been taken", [constraint: :unique, constraint_name: "commits_sha_index"]}
      ],
      data: %Commit{},
      valid?: false
    }

    expect(MockProject, :create_event, fn _ -> {:ok, %Event{}} end)

    expect(MockProject, :process_event, fn _ ->
      %{ok: [%Commit{}], error: [commit_error, commit_error]}
    end)

    conn =
      conn
      |> put_req_header("content-type", "application/json")
      |> put_req_header("x-hub-signature", "not checked on this context")
      |> put_req_header("x-github-delivery", "05b648a1-86cd-4777-bd5c-2e12302d75d3")
      |> put_req_header("x-github-event", "push")
      |> post("/api/events", @json_payload)

    assert json_response(conn, 400) == %{
             "success" => false,
             "error" => "Event successfully saved, but some processing failed"
           }
  end

  test "GET /events", %{conn: conn} do
    {:ok, _} =
      GithubProject.create_event(%{
        event_id: "05b648a1-86cd-4777-bd5c-2e12302d75d3",
        event_type: "push",
        raw_event: %{
          "repository" => %{
            "full_name" => "marcdel/ci_metrics_test"
          }
        }
      })

    [event] = Event.get_all()
    assert event.event_id == "05b648a1-86cd-4777-bd5c-2e12302d75d3"
    assert event.event_type == "push"

    conn = get(conn, "/events")

    assert response(conn, 200) =~ "05b648a1-86cd-4777-bd5c-2e12302d75d3"
    assert response(conn, 200) =~ "marcdel/ci_metrics_test"
  end

  test "GET /events?repository_id=:id", %{conn: conn} do
    expect(
      MockProject,
      :get_events_for,
      fn %{repository_id: "12345"} ->
        [
          %Event{
            id: 1,
            event_id: "event1",
            repository: %Repository{
              owner: "owner",
              name: "name"
            }
          },
          %Event{
            id: 2,
            event_id: "event2",
            repository: %Repository{
              owner: "owner",
              name: "name"
            }
          }
        ]
      end
    )

    conn = get(conn, "/events?repository_id=12345")

    assert response(conn, 200) =~ "event1"
    assert response(conn, 200) =~ "event2"
    assert response(conn, 200) =~ "owner/name"
  end

  test "GET /events/:id", %{conn: conn} do
    GithubProject.create_event(%{
      event_id: "05b648a1-86cd-4777-bd5c-2e12302d75d3",
      event_type: "push",
      raw_event: %{
        "repository" => %{
          "full_name" => "marcdel/ci_metrics_test"
        },
        "commits" => [%{"id" => "cbc47eabe663e87be4bd8d385abd99c54b53ac00"}]
      }
    })

    [event] = Event.get_all()

    conn = get(conn, "/events/#{event.id}")

    assert response(conn, 200) =~ "cbc47eabe663e87be4bd8d385abd99c54b53ac00"
    assert response(conn, 200) =~ "marcdel/ci_metrics_test"
  end
end
