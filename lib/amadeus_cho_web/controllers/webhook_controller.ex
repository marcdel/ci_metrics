defmodule AmadeusChoWeb.WebhookController do
  use AmadeusChoWeb, :controller
  alias AmadeusCho.{GithubClient, Webhook}
  require Logger

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"webhook" => webhook}) do
    webhook_request = %Webhook{
      repository_name: webhook["repository_name"],
      access_token: webhook["access_token"]
    }

    case GithubClient.create_webhook(webhook_request) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Webhook created.")
        |> render("new.html")

      {:error, _} ->
        conn
        |> put_flash(:error, "Error creating webhook.")
        |> render("new.html")
    end
  end
end
