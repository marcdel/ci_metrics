defmodule CiMetrics.Events.EventTest do
  use CiMetrics.DataCase, async: true
  alias CiMetrics.Events.Event
  alias CiMetrics.Project
  alias CiMetrics.Project.{Repository}

  test "get_all is ordered by repository id desc then by id desc" do
    Repository.insert_or_update(%{owner: "owner1", name: "repo1"})
    Repository.insert_or_update(%{owner: "owner2", name: "repo2"})

    Project.create_event(%{
      event_id: "event1",
      event_type: "push",
      raw_event: %{"repository" => %{"full_name" => "owner1/repo1"}}
    })

    Project.create_event(%{
      event_id: "event2",
      event_type: "push",
      raw_event: %{"repository" => %{"full_name" => "owner2/repo2"}}
    })

    Project.create_event(%{
      event_id: "event3",
      event_type: "push",
      raw_event: %{"repository" => %{"full_name" => "owner2/repo2"}}
    })

    Project.create_event(%{
      event_id: "event4",
      event_type: "push",
      raw_event: %{"repository" => %{"full_name" => "owner1/repo1"}}
    })

    assert ["event3", "event2", "event4", "event1"] == Event.get_all() |> get_event_ids()
  end

  defp get_event_ids(events) do
    events |> Enum.map(&Map.get(&1, :event_id))
  end
end
