defmodule AmadeusCho.GithubClientTest do
  import Mox
  use ExUnit.Case, async: true
  alias AmadeusCho.GithubClient
  setup :verify_on_exit!

  test "create_webhook/1 returns ok when receiving a 201" do
    expected_url = "https://api.github.com/repos/marcdel/amadeus_cho/hooks?access_token=1234509876"
    expected_headers = [{"content-type", "application/json"}]

    expected_body =
      "{\"active\":true,\"config\":{\"content_type\":\"json\",\"insecure_ssl\":\"0\",\"url\":\"localhost:4000/api/events\"},\"events\":[\"*\"],\"name\":\"web\"}"

    expect(MockHTTPClient, :post, fn ^expected_url, ^expected_headers, ^expected_body, [] ->
      {:ok, %Mojito.Response{
        body: "",
        complete: true,
        headers: [],
        status_code: 201
      }}
    end)

    result = GithubClient.create_webhook(%AmadeusCho.Webhook{
      repository_name: "marcdel/amadeus_cho",
      access_token: "1234509876",
      callback_url: "localhost:4000/api/events",
      events: ["*"]
    })

    assert result == {:ok, :webhook_created}
  end

  test "create_webhook/1 returns error when receiving a non-201" do
    expect(MockHTTPClient, :post, fn _, _, _, [] ->
      {:ok, %Mojito.Response{
        body: "",
        complete: true,
        headers: [],
        status_code: 301
      }}
    end)

    result = GithubClient.create_webhook(%AmadeusCho.Webhook{
      repository_name: "marcdel/amadeus_cho",
      access_token: "1234509876",
      callback_url: "localhost:4000/api/events",
      events: ["*"]
    })

    assert result == {:error, :webhook_error}
  end
end
