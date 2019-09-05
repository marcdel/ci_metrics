defmodule AmadeusCho.Webhook do
  defstruct [
    :repository_name,
    :access_token,
    callback_url: Application.get_env(:amadeus_cho, :webhook_callback_url),
    events: ["*"]
  ]
end
