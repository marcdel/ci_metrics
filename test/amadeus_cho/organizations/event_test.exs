defmodule AmadeusCho.EventTest do
  use AmadeusCho.DataCase, async: true
  alias AmadeusCho.{Event, Repository}

  test "get_all is ordered by repository id desc then by id desc" do
    {:ok, repo1} = Repository.insert_or_update(%{owner: "owner1", name: "repo1"})
    {:ok, repo2} = Repository.insert_or_update(%{owner: "owner2", name: "repo2"})

    Event.create_event(%{
      event_id: "event1",
      event_type: "push",
      repository_id: repo1.id,
      raw: %{"repository" => %{"full_name" => "owner1/repo1"}}
    })

    Event.create_event(%{
      event_id: "event2",
      event_type: "push",
      repository_id: repo2.id,
      raw: %{"repository" => %{"full_name" => "owner2/repo2"}}
    })

    Event.create_event(%{
      event_id: "event3",
      event_type: "push",
      repository_id: repo2.id,
      raw: %{"repository" => %{"full_name" => "owner2/repo2"}}
    })

    Event.create_event(%{
      event_id: "event4",
      event_type: "push",
      repository_id: repo1.id,
      raw: %{"repository" => %{"full_name" => "owner1/repo1"}}
    })

    assert ["event3", "event2", "event4", "event1"] == Event.get_all() |> get_event_ids()
  end

  test "get_for_repository/1" do
    {:ok, repo1} = Repository.insert_or_update(%{owner: "owner1", name: "repo1"})
    {:ok, repo2} = Repository.insert_or_update(%{owner: "owner2", name: "repo2"})

    Event.create_event(%{
      event_id: "event1",
      event_type: "push",
      repository_id: repo1.id,
      raw: %{"repository" => %{"full_name" => "owner1/repo1"}}
    })

    Event.create_event(%{
      event_id: "event2",
      event_type: "push",
      repository_id: repo2.id,
      raw: %{"repository" => %{"full_name" => "owner2/repo2"}}
    })

    Event.create_event(%{
      event_id: "event3",
      event_type: "push",
      repository_id: repo2.id,
      raw: %{"repository" => %{"full_name" => "owner2/repo2"}}
    })

    Event.create_event(%{
      event_id: "event4",
      event_type: "push",
      repository_id: repo1.id,
      raw: %{"repository" => %{"full_name" => "owner1/repo1"}}
    })

    assert ["event1", "event4"] == Event.get_for_repository(repo1.id) |> get_event_ids()
    assert ["event2", "event3"] == Event.get_for_repository(repo2.id) |> get_event_ids()
  end

  defp get_event_ids(events) do
    events |> Enum.map(&Map.get(&1, :event_id))
  end
end
