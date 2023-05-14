defmodule Connect4.Game.SchedulerTest do
  use Connect4.DataCase, async: false

  alias Connect4.Game.Runner
  alias Connect4.Game.Scheduler
  alias Phoenix.PubSub

  setup do
    {:ok, pid} = start_supervised(Scheduler)
    %{pid: pid}
  end

  describe "Connect4.Game.Scheduler" do
    test "is initially inactive" do
      refute Scheduler.active?()
    end

    test "has a default interval of 5 minutes" do
      assert Scheduler.interval_minutes() == 5
    end

    test "can be activated and deactivated" do
      Scheduler.activate(5)
      assert Scheduler.active?()
      assert Scheduler.interval_minutes() == 5
      Scheduler.deactivate()
      refute Scheduler.active?()
    end

    test "broadcasts the time remaining every second while active" do
      PubSub.subscribe(Connect4.PubSub, "scheduler")
      Scheduler.activate(5)
      assert_receive {:seconds_to_go, seconds_1}, 1500
      assert_receive {:seconds_to_go, seconds_2}, 1500
      assert seconds_1 - seconds_2 == 1
      Scheduler.deactivate()
      refute_receive {:seconds_to_go, _seconds}, 1500
    end

    test "broadcasts a message when deactivated" do
      PubSub.subscribe(Connect4.PubSub, "scheduler")
      Scheduler.deactivate()
      assert_receive :deactivated
    end

    test "starts games when the scheduled time is reached", %{pid: pid} do
      start_supervised!(Runner)
      PubSub.subscribe(Connect4.PubSub, "scheduler")
      insert(:player, code: "one", confirmed_at: DateTime.utc_now())
      insert(:player, code: "two", confirmed_at: DateTime.utc_now())
      send(pid, :start_round)
      assert_receive :round_started
      assert {:ok, _player, _game} = Runner.find_game("one")
      assert {:ok, _player, _game} = Runner.find_game("two")
    end
  end

  describe "Connect4.Game.Scheduler.seconds_to_go/1" do
    test "returns nil when inactive" do
      assert is_nil(Scheduler.seconds_to_go())
    end

    test "returns the number of seconds to the next scheduled game when active" do
      Scheduler.activate(5)
      assert Scheduler.seconds_to_go(~N[2023-05-10 22:28:30]) == 90
    end
  end
end
