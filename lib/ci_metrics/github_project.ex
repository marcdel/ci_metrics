defmodule CiMetrics.GithubProject do
  @behaviour CiMetrics.Project

  require Logger
  import Ecto.Query

  alias CiMetrics.{GithubClient, Repo}
  alias CiMetrics.Events.{Deployment, DeploymentStatus, Event, EventProcessor, Push}
  alias CiMetrics.Project.Repository

  def pushes_by_deployment(%{repository_id: repository_id}) do
    deployments_by_sha = deployments_by_sha(repository_id)

    pushes =
      Push
      |> where(repository_id: ^repository_id)
      |> order_by(asc: :id)
      |> Repo.all()

    pushes_by_before_sha =
      Enum.reduce(pushes, %{}, fn push, map ->
        Map.put(map, push.before_sha, push)
      end)

    add_pushes_to_deployments(%{
      push: hd(pushes),
      repository_id: repository_id,
      deployments_by_sha: deployments_by_sha,
      pushes_by_before_sha: pushes_by_before_sha,
      accumulator: %{current_pushes: [], all_pushes: %{}}
    })
    |> Map.get(:all_pushes)
  end

  defp deployments_by_sha(repository_id) do
    deployments_query =
      from deployment in Deployment,
        join: status in DeploymentStatus,
        on: deployment.deployment_id == status.deployment_id,
        where:
          deployment.repository_id == ^repository_id and
            status.status == "success",
        order_by: [desc: status.status_at],
        select: deployment

    deployments =
      deployments_query
      |> Repo.all()

    Enum.reduce(deployments, %{}, fn deployment, map ->
      Map.put(map, deployment.sha, deployment)
    end)
  end

  defp add_pushes_to_deployments(%{push: nil, accumulator: accumulator}), do: accumulator

  defp add_pushes_to_deployments(%{
         push: push,
         repository_id: repository_id,
         pushes_by_before_sha: pushes_by_before_sha,
         deployments_by_sha: deployments_by_sha,
         accumulator: %{
           current_pushes: current_pushes,
           all_pushes: all_pushes
         }
       }) do
    current_pushes = current_pushes ++ [push]
    deployment = Map.get(deployments_by_sha, push.after_sha)
    next_push = Map.get(pushes_by_before_sha, push.after_sha)

    updated_accumulator =
      if deployment != nil do
        # We hit a new deployment so that's all the pushes for the current deployment
        %{current_pushes: [], all_pushes: Map.put(all_pushes, deployment.sha, current_pushes)}
      else
        %{current_pushes: current_pushes, all_pushes: all_pushes}
      end

    add_pushes_to_deployments(%{
      push: next_push,
      repository_id: repository_id,
      pushes_by_before_sha: pushes_by_before_sha,
      deployments_by_sha: deployments_by_sha,
      accumulator: updated_accumulator
    })
  end

  def create_webhook(repository_name, access_token) do
    GithubClient.create_webhook(%{
      repository_name: repository_name,
      access_token: access_token,
      callback_url: Application.get_env(:ci_metrics, :webhook_callback_url),
      events: ["*"]
    })
  end

  @impl CiMetrics.Project
  def create_event(%{event_id: event_id, event_type: event_type, raw_event: raw_event}) do
    {:ok, repository} = Repository.from_raw_event(raw_event)

    attrs = %{
      event_id: event_id,
      event_type: event_type,
      repository_id: repository.id,
      raw: raw_event
    }

    Event.insert_or_update(attrs)
  end

  @impl CiMetrics.Project
  def process_event(%Event{event_type: "push"} = event) do
    EventProcessor.process(%Push{event: event})
  end

  def process_event(%Event{event_type: "deployment"} = event) do
    EventProcessor.process(%Deployment{event: event})
  end

  def process_event(%Event{event_type: "deployment_status"} = event) do
    EventProcessor.process(%DeploymentStatus{event: event})
  end

  def process_event(%Event{event_type: event_type}) do
    Logger.error("Process not defined for #{event_type}")
    %{ok: [], error: []}
  end

  @impl CiMetrics.Project
  def get_events_for(%{repository_id: id}) when is_binary(id) do
    id
    |> Integer.parse()
    |> Tuple.to_list()
    |> List.first()
    |> do_get_events_for_repository()
  end

  def get_events_for(%{repository_id: id}) when is_integer(id) do
    do_get_events_for_repository(id)
  end

  defp do_get_events_for_repository(id) do
    Event
    |> where(repository_id: ^id)
    |> Repo.all()
    |> Repo.preload(:repository)
  end
end