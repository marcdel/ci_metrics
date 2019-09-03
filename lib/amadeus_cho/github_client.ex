defmodule AmadeusCho.GithubClient do
  require Logger

  @http_client Application.get_env(
                 :amadeus_cho,
                 :http_client,
                 AmadeusCho.HTTPClient
               )

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

    with {:ok, response} <-
           @http_client.post(url, [{"content-type", "application/json"}], body, []),
         {:ok, _} <- validate_response(response) do
      {:ok, :webhook_created}
    else
      {:error, :webhook_exists, response} ->
        Logger.error(
          "Error creating webhook for #{webhook.repository_name}: #{inspect(response.body)}"
        )

        {:error, :webhook_exists}

      {:error, :repository_not_found, response} ->
        Logger.error(
          "Error creating webhook for #{webhook.repository_name} (repository not found): #{
            inspect(response.body)
          }"
        )

        {:error, :repository_not_found}

      {:error, :invalid_credentials, response} ->
        Logger.error(
          "Error creating webhook for #{webhook.repository_name} (invalid credentials): #{
            inspect(response.body)
          }"
        )

        {:error, :invalid_credentials}

      {:error, response} ->
        Logger.error(
          "Error creating webhook for #{webhook.repository_name}: #{inspect(response)}"
        )

        {:error, :webhook_error}
    end
  end

  defp validate_response(%{status_code: 422} = response) do
    {:error, :webhook_exists, response}
  end

  defp validate_response(%{status_code: 404} = response) do
    {:error, :repository_not_found, response}
  end

  defp validate_response(%{status_code: 401} = response) do
    {:error, :invalid_credentials, response}
  end

  defp validate_response(%{status_code: 201}), do: {:ok, nil}
  defp validate_response(response), do: {:error, response}
end
