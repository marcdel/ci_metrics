defmodule AmadeusCho.Repo do
  use Ecto.Repo,
    otp_app: :amadeus_cho,
    adapter: Ecto.Adapters.Postgres
end
