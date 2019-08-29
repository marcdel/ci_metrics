# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :amadeus_cho,
  ecto_repos: [AmadeusCho.Repo]

# Configures the endpoint
config :amadeus_cho, AmadeusChoWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "dkeOpsTmpVZH0LLcq33qTptv633ZtDYVMKwDVGEFHw7zR8QY7HGIPZ1HvR7IjO4s",
  render_errors: [view: AmadeusChoWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: AmadeusCho.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
