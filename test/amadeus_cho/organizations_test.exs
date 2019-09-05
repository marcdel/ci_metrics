defmodule AmadeusCho.OrganizationsTest do
  use AmadeusCho.DataCase, async: true
  alias AmadeusCho.{Event, Organizations, Repository}

  describe "create_event/3" do
    test "creates a repository if one isn't found" do
      event_id = "05b648a1-86cd-4777-bd5c-2e12302d75d3"
      event_type = "push"

      raw_event =
        "../support/push.json"
        |> Path.expand(__DIR__)
        |> File.read!()
        |> Jason.decode!()

      Organizations.create_event(%{
        event_id: event_id,
        event_type: event_type,
        raw_event: raw_event
      })

      [repository] = Repository.get_all()
      assert repository.name == "amadeus_cho_test"
      assert repository.owner == "marcdel"

      [event] = Event.get_all()
      assert event.event_id == "05b648a1-86cd-4777-bd5c-2e12302d75d3"
      assert event.event_type == "push"
      assert event.repository_id == repository.id
    end
  end
end
