defmodule CiMetricsWeb.WebhookController do
  use CiMetricsWeb, :controller
  alias CiMetrics.GithubProject

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"repository_name" => repository_name, "access_token" => access_token}) do
    with {:ok, repository} <- GithubProject.create_repository(repository_name),
         {:ok, :webhook_created} <- GithubProject.create_webhook(repository, access_token) do
      conn
      |> put_flash(:info, "Webhook created.")
      |> render("new.html")
    else
      {:error, error} ->
        error_message = error_to_user_message(error)

        conn
        |> put_flash(:error, error_message)
        |> render("new.html")
    end
  end

  def error_to_user_message(:webhook_exists),
    do: "Oops! This repository already has a webhook from us."

  def error_to_user_message(:repository_not_found), do: "Oops! We couldn't find that repository."

  def error_to_user_message(:invalid_credentials),
    do: "Oops! The access token you provided doesn't seem to be working."

  def error_to_user_message(:webhook_error),
    do: "Oops! We had some trouble creating your webhook."

  def error_to_user_message(_), do: "Oops! We had some trouble creating your webhook."
end
