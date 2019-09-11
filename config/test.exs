use Mix.Config

# Configure your database
config :amadeus_cho, AmadeusCho.Repo,
  username: "postgres",
  password: "postgres",
  database: "amadeus_cho_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :amadeus_cho, AmadeusChoWeb.Endpoint,
  http: [port: 4002],
  server: false

config :amadeus_cho, webhook_callback_url: "localhost:4000/api/events"

# Mocks
config :amadeus_cho, :http_client, MockHTTPClient
config :amadeus_cho, :project, MockProject

# Print only warnings and errors during test
config :logger, level: :warn
