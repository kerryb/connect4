defmodule Connect4.Game.SchedulerTest do
  use ExUnit.Case, async: false

  alias Connect4.Game.Scheduler

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
  end
end
