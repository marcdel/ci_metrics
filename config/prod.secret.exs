# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
use Mix.Config

database_url =
  System.get_env("DATABASE_URL") ||
    raise """
    environment variable DATABASE_URL is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

config :ci_metrics, CiMetrics.Repo,
  ssl: true,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

config :ci_metrics, CiMetricsWeb.Endpoint,
  http: [:inet6, port: String.to_integer(System.get_env("PORT") || "4000")],
  secret_key_base: secret_key_base

webhook_callback_url =
  System.get_env("WEBHOOK_CALLBACK_URL") ||
    raise """
    Environment variable WEBHOOK_CALLBACK_URL is missing.
    For example: http://aaf59627.ngrok.io/api/events
    """

config :ci_metrics, webhook_callback_url: webhook_callback_url

github_secret =
  System.get_env("GITHUB_SECRET") ||
    raise "Environment variable GITHUB_SECRET is missing."

config :ci_metrics, github_secret: github_secret

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
#     config :ci_metrics, CiMetricsWeb.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.
