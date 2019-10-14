defmodule CiMetrics.GithubClientTest do
  import Mox
  use ExUnit.Case, async: true
  alias CiMetrics.GithubClient

  setup :verify_on_exit!

  test "create_webhook/1 returns ok when receiving a 201" do
    expected_url = "https://api.github.com/repos/marcdel/ci_metrics/hooks?access_token=1234509876"

    expected_headers = [{"content-type", "application/json"}]

    expected_body =
      Jason.encode!(%{
        active: true,
        config: %{
          content_type: "json",
          insecure_ssl: "0",
          url: "localhost:4000/api/events",
          secret: Application.get_env(:ci_metrics, :github_secret)
        },
        events: ["*"],
        name: "web"
      })

    expect(MockHTTPClient, :post, fn ^expected_url, ^expected_headers, ^expected_body, [] ->
      {:ok,
       %Mojito.Response{
         body: "",
         complete: true,
         headers: [],
         status_code: 201
       }}
    end)

    result =
      GithubClient.create_webhook(%{
        repository_name: "marcdel/ci_metrics",
        access_token: "1234509876",
        callback_url: "localhost:4000/api/events",
        events: ["*"]
      })

    assert result == {:ok, :webhook_created}
  end

  test "create_webhook/1 returns error when receiving a non-201" do
    expect(MockHTTPClient, :post, fn _, _, _, [] ->
      {:ok,
       %Mojito.Response{
         body: "",
         complete: true,
         headers: [],
         status_code: 301
       }}
    end)

    result = GithubClient.create_webhook(generic_webhook_request())

    assert result == {:error, :webhook_error}
  end

  test "existing webhook" do
    invalid_response_body =
      Jason.encode!(%{
        message: "Validation Failed",
        errors: [
          %{
            resource: "Hook",
            code: "custom",
            message: "Hook already exists on this repository"
          }
        ],
        documentation_url: "https://developer.github.com/v3/repos/hooks/#create-a-hook"
      })

    expect(MockHTTPClient, :post, fn _, _, _, [] ->
      {:ok,
       %Mojito.Response{
         body: invalid_response_body,
         complete: true,
         headers: [],
         status_code: 422
       }}
    end)

    result = GithubClient.create_webhook(generic_webhook_request())

    assert result == {:error, :webhook_exists}
  end

  test "repository not found" do
    invalid_response_body =
      Jason.encode!(%{
        message: "Not Found",
        documentation_url: "https://developer.github.com/v3/repos/hooks/#create-a-hook"
      })

    expect(MockHTTPClient, :post, fn _, _, _, [] ->
      {:ok,
       %Mojito.Response{
         body: invalid_response_body,
         complete: true,
         headers: [],
         status_code: 404
       }}
    end)

    result = GithubClient.create_webhook(generic_webhook_request())

    assert result == {:error, :repository_not_found}
  end

  test "invalid credentials" do
    expect(MockHTTPClient, :post, fn _, _, _, [] ->
      {:ok,
       %Mojito.Response{
         body:
           "{\"message\": \"Bad credentials\", \"documentation_url\": \"https://developer.github.com/v3\" }",
         complete: true,
         headers: [],
         status_code: 401
       }}
    end)

    result = GithubClient.create_webhook(generic_webhook_request())

    assert result == {:error, :invalid_credentials}
  end

  defp generic_webhook_request do
    %{
      repository_name: "",
      access_token: "",
      events: [],
      callback_url: ""
    }
  end
end
