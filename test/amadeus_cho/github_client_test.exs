defmodule AmadeusCho.GithubClientTest do
  import Mox
  use ExUnit.Case, async: true
  alias AmadeusCho.GithubClient
  setup :verify_on_exit!

  test "create_webhook/1 returns ok when receiving a 201" do
    expected_url =
      "https://api.github.com/repos/marcdel/amadeus_cho/hooks?access_token=1234509876"

    expected_headers = [{"content-type", "application/json"}]

    expected_body =
      "{\"active\":true,\"config\":{\"content_type\":\"json\",\"insecure_ssl\":\"0\",\"url\":\"localhost:4000/api/events\"},\"events\":[\"*\"],\"name\":\"web\"}"

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
      GithubClient.create_webhook(%AmadeusCho.Webhook{
        repository_name: "marcdel/amadeus_cho",
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

    result = GithubClient.create_webhook(%AmadeusCho.Webhook{})

    assert result == {:error, :webhook_error}
  end

  test "existing webhook" do
    expect(MockHTTPClient, :post, fn _, _, _, [] ->
      {:ok,
       %Mojito.Response{
         body:
           "{\"message\": \"Validation Failed\", \"errors\": [{\"resource\": \"Hook\", \"code\": \"custom\", \"message\": \"Hook already exists on this repository\"}], \"documentation_url\": \"https://developer.github.com/v3/repos/hooks/#create-a-hook\"}",
         complete: true,
         headers: [],
         status_code: 422
       }}
    end)

    result = GithubClient.create_webhook(%AmadeusCho.Webhook{})

    assert result == {:error, :webhook_exists}
  end

  test "repository not found" do
    expect(MockHTTPClient, :post, fn _, _, _, [] ->
      {:ok,
       %Mojito.Response{
         body:
           "{\"message\": \"Not Found\", \"documentation_url\": \"https://developer.github.com/v3/repos/hooks/#create-a-hook\" }",
         complete: true,
         headers: [],
         status_code: 404
       }}
    end)

    result = GithubClient.create_webhook(%AmadeusCho.Webhook{})

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

    result = GithubClient.create_webhook(%AmadeusCho.Webhook{})

    assert result == {:error, :invalid_credentials}
  end
end
