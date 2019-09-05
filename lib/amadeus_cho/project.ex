defmodule AmadeusCho.Project do
  alias AmadeusCho.{Event, GithubClient, Repo, Repository}
  import Ecto.Query, only: [where: 2]

  def create_webhook(repository_name, access_token) do
    GithubClient.create_webhook(%{
      repository_name: repository_name,
      access_token: access_token,
      callback_url: Application.get_env(:amadeus_cho, :webhook_callback_url),
      events: ["*"]
    })
  end

  def create_event(%{event_id: event_id, event_type: event_type, raw_event: raw_event}) do
    {:ok, repository} =
      raw_event
      |> extract_repository_info()
      |> Repository.insert_or_update()

    attrs = %{
      event_id: event_id,
      event_type: event_type,
      repository_id: repository.id,
      raw: raw_event
    }

    %Event{}
    |> Event.raw_event_changeset(attrs)
    |> Repo.insert()
  end

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

  defp do_get_events_for_repository(id) when is_integer(id) do
    Event
    |> where(repository_id: ^id)
    |> Repo.all()
    |> Repo.preload(:repository)
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
