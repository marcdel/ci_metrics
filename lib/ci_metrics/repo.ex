defmodule CiMetrics.Repo do
  use Ecto.Repo,
    otp_app: :ci_metrics,
    adapter: Ecto.Adapters.Postgres
end
