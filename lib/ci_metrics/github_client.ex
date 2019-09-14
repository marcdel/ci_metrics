defmodule CiMetrics.GithubClient do
  require Logger

  @http_client Application.get_env(:ci_metrics, :http_client, CiMetrics.HTTPClient)

  @callback create_webhook(map()) :: {:ok, nil} | {:error, any()}
  def create_webhook(webhook) do
    url =
      "https://api.github.com/repos/#{webhook.repository_name}/hooks?access_token=#{
        webhook.access_token
      }"

    body =
      Jason.encode!(%{
        "name" => "web",
        "active" => true,
        "events" => webhook.events,
        "config" => %{
          "url" => webhook.callback_url,
          "content_type" => "json",
          "insecure_ssl" => "0"
        }
      })

    {_, response} = @http_client.post(url, [{"content-type", "application/json"}], body, [])

    validate_response(webhook.repository_name, response)
  end

  defp validate_response(_, %{status_code: 201}), do: {:ok, :webhook_created}

  defp validate_response(name, %{status_code: 422, body: body}) do
    Logger.error("Error creating webhook for #{name}: #{inspect(body)}")
    {:error, :webhook_exists}
  end

  defp validate_response(name, %{status_code: 404, body: body}) do
    Logger.error("Error creating webhook for #{name} (repository not found): #{inspect(body)}")
    {:error, :repository_not_found}
  end

  defp validate_response(name, %{status_code: 401, body: body}) do
    Logger.error("Error creating webhook for #{name} (invalid credentials): #{inspect(body)}")
    {:error, :invalid_credentials}
  end

  defp validate_response(name, response) do
    Logger.error("Error creating webhook for #{name}: #{inspect(response)}")
    {:error, :webhook_error}
  end
end
