defmodule CiMetricsWeb.EventView do
  use CiMetricsWeb, :view

  def repository_full_name(repository) do
    "#{repository.owner}/#{repository.name}"
  end
end
