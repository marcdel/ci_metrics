File.exists?(Path.expand("~/.iex.exs")) && import_file("~/.iex.exs")

alias CiMetrics.GithubProject
alias CiMetrics.Events.{Push, Event, EventProcessor, Deployment, DeploymentStatus, Push}
alias CiMetrics.Project.{Commit, Repository}
alias CiMetrics.Metrics.{MetricSnapshot, TimeUnitMetric, LeadTime}
alias CiMetrics.{GithubClient, HTTPClient, Repo}
