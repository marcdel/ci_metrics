defmodule CiMetrics.Metrics.DeploymentFrequency do
  alias CiMetrics.Events.DeploymentStatus
  alias CiMetrics.Metrics.TimeUnitMetric

  def calculate(repository_id) when is_binary(repository_id) do
    repository_id
    |> Integer.parse()
    |> Tuple.to_list()
    |> List.first()
    |> calculate()
  end

  def calculate(repository_id) when is_integer(repository_id) do
    deployments_statuses = DeploymentStatus.get_successful_deployment_statuses_for(repository_id)

    deployments_statuses
    |> Enum.reduce({[], nil}, fn
      current, {[], nil} ->
        {[], current}

      current, {diffs, previous} ->
        diff = DateTime.diff(previous.status_at, current.status_at, :second)
        {diffs ++ [diff], current}
    end)
    |> Tuple.to_list()
    |> List.first()
    |> calculate_average()
    |> to_integer()
    |> to_time_unit_metric()
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
