defmodule AmadeusChoWeb.EventView do
  use AmadeusChoWeb, :view

  def truncate(raw_event) do
    raw_event
    |> inspect(pretty: true)
    |> String.slice(0..50)
  end
end
