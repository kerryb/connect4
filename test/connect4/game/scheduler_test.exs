defmodule Connect4.Game.SchedulerTest do
  use ExUnit.Case, async: false

  alias Connect4.Game.Scheduler
  alias Phoenix.PubSub

  setup do
    {:ok, _pid} = start_supervised(Scheduler)
    :ok
  end

  describe "Connect4.Game.Scheduler" do
    test "is initially inactive" do
      refute Scheduler.active?()
    end

    test "has a default interval of 10 minutes" do
      assert Scheduler.interval_minutes() == 10
    end

    test "can be activated and deactivated" do
      Scheduler.activate()
      assert Scheduler.active?()
      Scheduler.deactivate()
      refute Scheduler.active?()
    end

    test "broadcasts the time remaining every second while active" do
      PubSub.subscribe(Connect4.PubSub, "scheduler")
      Scheduler.activate()
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
  end

  describe "Connect4.Game.Scheduler.seconds_to_go/1" do
    test "returns nil when inactive" do
      assert is_nil(Scheduler.seconds_to_go())
    end

    test "returns the number of seconds to the next scheduled game when active" do
      Scheduler.activate()
      assert Scheduler.seconds_to_go(~N[2023-05-10 22:28:30]) == 90
    end
  end
end
