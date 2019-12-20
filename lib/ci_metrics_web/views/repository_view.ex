defmodule CiMetricsWeb.RepositoryView do
  use CiMetricsWeb, :view

  def full_name(%{owner: owner, name: name}) do
    "#{owner}/#{name}"
  end

  def deployment_strategies do
    [
      [key: "Heroku", value: :heroku],
      [key: "Github Actions (coming soon!)", value: :github_actions, disabled: true],
      [key: "Travis CI", value: :travis_ci, disabled: true],
      [key: "Circle CI", value: :circle_ci, disabled: true],
      [key: "Semaphore CI", value: :semaphore_ci, disabled: true],
      [key: "Gitlab CI", value: :gitlab_ci, disabled: true],
      [key: "Jenkins", value: :jenkins, disabled: true]
    ]
  end
end
