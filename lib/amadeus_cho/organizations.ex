defmodule AmadeusCho.Organizations do
  alias AmadeusCho.{Event, Repository}

  def create_event(%{event_id: event_id, event_type: event_type, raw_event: raw_event}) do
    {:ok, repository} =
      raw_event
      |> extract_repository_info()
      |> Repository.insert_or_update()

    Event.create_event(%{
      event_id: event_id,
      event_type: event_type,
      repository_id: repository.id,
      raw: raw_event
    })
  end

  defp extract_repository_info(raw_event) do
    repository_full_name = Kernel.get_in(raw_event, ["repository", "full_name"])
    git_url = Kernel.get_in(raw_event, ["repository", "git_url"])

    [owner, name] = do_extract_repository_info(repository_full_name, git_url)

    %{owner: owner, name: name}
  end

  defp do_extract_repository_info(nil, git_url) do
    git_url
    |> URI.parse()
    |> Map.get(:path)
    |> Path.rootname()
    |> Path.relative()
    |> Path.split()
  end

  defp do_extract_repository_info(repository_full_name, _) do
    String.split(repository_full_name, "/")
  end
end
