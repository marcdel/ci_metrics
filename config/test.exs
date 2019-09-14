use Mix.Config

# Configure your database
config :ci_metrics, CiMetrics.Repo,
  username: "postgres",
  password: "postgres",
  database: "ci_metrics_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ci_metrics, CiMetricsWeb.Endpoint,
  http: [port: 4002],
  server: false

config :ci_metrics, webhook_callback_url: "localhost:4000/api/events"

# Mocks
config :ci_metrics, :http_client, MockHTTPClient
config :ci_metrics, :project, MockProject

# Print only warnings and errors during test
config :logger, level: :warn
