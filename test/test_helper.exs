ExUnit.start(capture_log: true)
Ecto.Adapters.SQL.Sandbox.mode(AmadeusCho.Repo, :manual)
Mox.defmock(MockHTTPClient, for: AmadeusCho.HTTPClient)
