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

      {:error, error} ->
        error_message =
          case error do
            :webhook_exists ->
              "Oops! This repository already has a webhook from us."

            :repository_not_found ->
              "Oops! We couldn't find that repository."

            :invalid_credentials ->
              "Oops! The access token you provided doesn't seem to be working."

            :webhook_error ->
              "Oops! We had some trouble creating your webhook."
          end

        conn
        |> put_flash(:error, error_message)
        |> render("new.html")
    end
  end
end
