defmodule AmadeusChoWeb.WebhookController do
  use AmadeusChoWeb, :controller
  alias AmadeusCho.Project

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"repository_name" => repository_name, "access_token" => access_token}) do
    case Project.create_webhook(repository_name, access_token) do
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
