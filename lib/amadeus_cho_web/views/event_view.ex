defmodule AmadeusChoWeb.EventView do
  use AmadeusChoWeb, :view

  def repository_full_name(repository) do
    "#{repository.owner}/#{repository.name}"
  end
end
