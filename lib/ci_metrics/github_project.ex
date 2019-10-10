defmodule CiMetrics.GithubProject do
  @behaviour CiMetrics.Project

  require Logger
  import Ecto.Query

  alias CiMetrics.{GithubClient, Repo}
  alias CiMetrics.Events.{Deployment, DeploymentStatus, Event, EventProcessor, Push}
  alias CiMetrics.Metrics.TimeUnitMetric
  alias CiMetrics.Project.Repository

  def pushes_by_deployment(repository_id) do
    deployments_by_sha = deployments_by_sha(repository_id)

    pushes =
      Push
      |> where(repository_id: ^repository_id)
      |> order_by(asc: :id)
      |> Repo.all()
      |> Repo.preload(:commits)

    pushes_by_before_sha =
      Enum.reduce(pushes, %{}, fn push, map ->
        Map.put(map, push.before_sha, push)
      end)

    pushes
    |> Enum.reduce(%{current_pushes: [], all_pushes: %{}}, fn push, accumulator ->
      add_pushes_to_deployments(%{
        push: push,
        repository_id: repository_id,
        deployments_by_sha: deployments_by_sha,
        pushes_by_before_sha: pushes_by_before_sha,
        accumulator: accumulator
      })
    end)
    |> Map.get(:all_pushes)
  end

  @impl CiMetrics.Project
  def calculate_lead_time(repository_id) when is_binary(repository_id) do
    repository_id
    |> Integer.parse()
    |> Tuple.to_list()
    |> List.first()
    |> calculate_lead_time()
  end

  def calculate_lead_time(repository_id) when is_integer(repository_id) do
    pushes_by_deployment = pushes_by_deployment(repository_id)
    deployments_by_sha = deployments_by_sha(repository_id)

    deployments_by_sha
    |> Map.values()
    |> Enum.flat_map(fn deployment ->
      deployment_status =
        deployment.deployment_statuses
        |> Enum.find(fn %{status: status} -> status == "success" end)

      pushes_by_deployment
      |> Map.get(deployment.sha, [])
      |> Enum.flat_map(fn push -> push.commits end)
      |> Enum.map(fn commit ->
        DateTime.diff(deployment_status.status_at, commit.committed_at, :second)
      end)
    end)
    |> calculate_average()
    |> to_integer()
    |> to_time_unit_metric()
  end

  defp calculate_average([]), do: 0
  defp calculate_average(numbers), do: Enum.sum(numbers) / Enum.count(numbers)

  defp to_time_unit_metric(time), do: TimeUnitMetric.new(time)

  defp to_integer(time) when is_integer(time), do: time

  defp to_integer(time) when is_float(time) do
    time
    |> Decimal.from_float()
    |> Decimal.round(0)
    |> Decimal.to_integer()
  end

  defp deployments_by_sha(repository_id) do
    deployments_query =
      from deployment in Deployment,
        join: status in DeploymentStatus,
        on: deployment.deployment_id == status.deployment_id,
        preload: [deployment_statuses: status],
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
         deployments_by_sha: deployments_by_sha,
         accumulator: %{
           current_pushes: current_pushes,
           all_pushes: all_pushes
         }
       }) do
    current_pushes = current_pushes ++ [push]
    deployment = Map.get(deployments_by_sha, push.after_sha)

    if deployment != nil do
      # We found a deployment so all the pushes since the last deployment get associated with it
      %{current_pushes: [], all_pushes: Map.put(all_pushes, deployment.sha, current_pushes)}
    else
      %{current_pushes: current_pushes, all_pushes: all_pushes}
    end
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
