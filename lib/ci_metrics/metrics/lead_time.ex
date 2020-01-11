defmodule CiMetrics.Metrics.LeadTime do
  import Ecto.Query

  alias CiMetrics.Repo
  alias CiMetrics.Events.{Deployment, Push}
  alias CiMetrics.Metrics.TimeUnitMetric

  @doc """
    Returns the average lead time for commits/deployments between 30 days ago and today
  """
  def last_30_days(repository_id) do
    for_date_range(repository_id, 30, 0)
  end

  @doc """
    Returns the average lead time for commits/deployments between 60 days ago and 30 days ago
  """
  def previous_30_days(repository_id) do
    for_date_range(repository_id, 60, 30)
  end

  defp for_date_range(repository_id, from_days_ago, to_days_ago) do
    repository_id = parse_repository_id(repository_id)

    date_range =
      Date.range(
        Date.utc_today() |> Date.add(-from_days_ago),
        Date.utc_today() |> Date.add(-to_days_ago)
      )

    deployments_by_sha = deployments_by_sha(repository_id, date_range)
    pushes_by_deployment = pushes_by_deployment(repository_id, deployments_by_sha)

    deployments_by_sha
    |> Map.values()
    |> Enum.flat_map(fn deployment ->
      deployment_status =
        deployment.deployment_statuses
        |> Enum.find(fn %{status: status} -> status == "success" end)

      pushes_by_deployment
      |> Map.get(deployment.sha, [])
      |> Enum.flat_map(fn push -> push.commits end)
      |> Enum.filter(fn commit -> in_range_inclusive(commit.committed_at, date_range) end)
      |> Enum.map(fn commit ->
        DateTime.diff(deployment_status.status_at, commit.committed_at, :second)
      end)
    end)
    |> calculate_average()
    |> to_integer()
    |> to_time_unit_metric()
  end

  def all_time_average(repository_id) do
    repository_id = parse_repository_id(repository_id)

    deployments_by_sha = deployments_by_sha(repository_id)
    pushes_by_deployment = pushes_by_deployment(repository_id, deployments_by_sha)

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

  def pushes_by_deployment(repository_id) do
    deployments_by_sha = deployments_by_sha(repository_id)
    pushes_by_deployment(repository_id, deployments_by_sha)
  end

  def pushes_by_deployment(repository_id, deployments_by_sha) do
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

  defp in_range_inclusive(time, %{first: first, last: last}) do
    compared_to_first = Date.compare(time, first)
    compared_to_last = Date.compare(time, last)

    (compared_to_first == :gt || compared_to_first == :eq) &&
      (compared_to_last == :lt || compared_to_last == :eq)
  end

  defp deployments_by_sha(repository_id, date_range) do
    deployments = Deployment.get_successful_deployments_for(repository_id, date_range)

    Enum.reduce(deployments, %{}, fn deployment, map ->
      Map.put(map, deployment.sha, deployment)
    end)
  end

  defp deployments_by_sha(repository_id) do
    deployments = Deployment.get_successful_deployments_for(repository_id)

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

  defp parse_repository_id(repository_id) when is_integer(repository_id), do: repository_id

  defp parse_repository_id(repository_id) when is_binary(repository_id) do
    repository_id
    |> Integer.parse()
    |> Tuple.to_list()
    |> List.first()
  end

  defp calculate_average([]), do: 0

  defp calculate_average(numbers), do: Enum.sum(numbers) / Enum.count(numbers)

  defp to_time_unit_metric(seconds), do: TimeUnitMetric.new(seconds)

  defp to_integer(time) when is_integer(time), do: time

  defp to_integer(time) when is_float(time) do
    time
    |> Decimal.from_float()
    |> Decimal.round(0)
    |> Decimal.to_integer()
  end
end
