File.exists?(Path.expand("~/.iex.exs")) && import_file("~/.iex.exs")

alias CiMetrics.Project
alias CiMetrics.Project.{Commit, Deployment, Event, Repository}
alias CiMetrics.{GithubClient, HTTPClient, Repo}
