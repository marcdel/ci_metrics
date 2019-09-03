defmodule AmadeusChoWeb.Router do
  use AmadeusChoWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AmadeusChoWeb do
    pipe_through :browser

    get "/", PageController, :index
    resources "/webhooks", WebhookController, only: [:new, :create]
  end

  scope "/api", AmadeusChoWeb do
    pipe_through :api

    resources "/events", EventController, only: [:create]
  end
end
