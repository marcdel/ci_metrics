File.exists?(Path.expand("~/.iex.exs")) && import_file("~/.iex.exs")

alias AmadeusCho.Project
alias AmadeusCho.Project.{Commit, Event, Repository}
alias AmadeusCho.{GithubClient, HTTPClient, Repo}
