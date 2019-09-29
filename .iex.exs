File.exists?(Path.expand("~/.iex.exs")) && import_file("~/.iex.exs")

alias CiMetrics.Project
alias CiMetrics.Events.{Push, Deployment, Event, EventProcessor, Push}
alias CiMetrics.Project.{Commit, DeploymentStatus, Event, Repository}
alias CiMetrics.{GithubClient, HTTPClient, Repo}
