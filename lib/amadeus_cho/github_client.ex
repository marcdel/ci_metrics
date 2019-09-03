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

    with {:ok, response} <- @http_client.post(url, [{"content-type", "application/json"}], body, []),
         {:ok, _} <- response_created?(response)
    do
      {:ok, :webhook_created}
    else
      {:error, error} ->
        Logger.error("Error creating webhook for #{webhook.repository_name}: #{inspect(error)}")
        {:error, :webhook_error}
    end
  end

  defp response_created?(%{status_code: 201}), do: {:ok, nil}
  defp response_created?(response), do: {:error, response}
end
