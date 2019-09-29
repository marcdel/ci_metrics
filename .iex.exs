File.exists?(Path.expand("~/.iex.exs")) && import_file("~/.iex.exs")

alias CiMetrics.Project
alias CiMetrics.Events.{Push, Event, EventProcessor, Deployment, DeploymentStatus, Push}
alias CiMetrics.Project.{Commit, Repository}
alias CiMetrics.{GithubClient, HTTPClient, Repo}
