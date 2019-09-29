defmodule CiMetrics.Events.PushEventProcessorTest do
  use CiMetrics.DataCase, async: true

  alias CiMetrics.Events.{EventProcessor, Push}
  alias CiMetrics.Project.Commit

  describe "process/1" do
    test "push event creates a push record and associates its commits" do
      event = CreateEvent.multi_push()

      %{ok: _, error: []} = EventProcessor.process(%Push{event: event})
      [push] = Push.get_all()

      assert [commit1, commit2] = push.commits
      assert push.event_id == event.id
      assert push.repository_id == event.repository_id

      assert commit1.sha == "b5ec9bbdd6a75451e02f9a464fe2418d9eaead81"
      assert commit1.branch == "master"
      assert DateTime.to_string(commit1.committed_at) == "2019-09-06 03:26:10Z"
      assert commit1.event_id == event.id
      assert commit1.repository_id == event.repository_id

      assert commit2.sha == "8dfe6b686e0bf1a2860b03f6d2e4567002d3fdda"
      assert commit2.branch == "master"
      assert DateTime.to_string(commit2.committed_at) == "2019-09-06 03:26:16Z"
      assert commit1.event_id == event.id
      assert commit1.repository_id == event.repository_id
    end

    test "cannot create the same commit twice" do
      event = CreateEvent.multi_push()

      %{ok: [commit1, commit2], error: []} = EventProcessor.process(%Push{event: event})
      %{ok: [^commit1, ^commit2], error: []} = EventProcessor.process(%Push{event: event})

      assert Commit.get_all() |> Enum.count() == 2
    end
  end
end
