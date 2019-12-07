defmodule CiMetricsWeb.RepositoryView do
  use CiMetricsWeb, :view

  def full_name(%{owner: owner, name: name}) do
    "#{owner}/#{name}"
  end

  def deployment_strategies do
    [
      "Please select one": nil,
      Heroku: "heroku"
    ]
  end
end
