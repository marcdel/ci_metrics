defmodule CiMetricsWeb.RepositoryView do
  use CiMetricsWeb, :view

  def full_name(%{owner: owner, name: name}) do
    "#{owner}/#{name}"
  end
end
