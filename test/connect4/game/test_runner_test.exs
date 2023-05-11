defmodule Connect4.Game.TestRunnerTest do
  use ExUnit.Case, async: false

  alias Connect4.Game.TestRunner

  setup do
    {:ok, _pid} = start_supervised(TestRunner)
    :ok
  end

  describe "Connect4.Game.TestRunner.play/2" do
    test "plays the first move in and returns a new game if one is not in progess" do
      assert {:ok, %{next_player: :X, board: %{3 => %{0 => :O}}}} = TestRunner.play("one", "3")
    end

    test "plays as alternating players, and returns the updated game" do
      TestRunner.play("one", "3")
      assert {:ok, %{next_player: :O, board: %{3 => %{0 => :O, 1 => :X}}}} = TestRunner.play("one", "3")
    end

    test "starts a new game when the previous one is completed" do
      for column <- ~w[0 1 0 1 0 1 0], do: TestRunner.play("one", column)
      assert {:ok, %{next_player: :X, board: %{0 => %{0 => :O}}}} = TestRunner.play("one", "0")
    end

    test "passes on any error from the game" do
      assert {:error, "Column must be 0..6"} = TestRunner.play("two", "8")
    end
  end

  describe "Connect4.Game.TestRunner.find_or_start_game/1" do
    test "returns a new game if one is not in progess" do
      assert {:ok, %{board: %{}}} = TestRunner.find_or_start_game("one")
    end

    test "returns an in-progress game if found" do
      TestRunner.play("one", "3")
      assert {:ok, %{board: %{3 => %{0 => :O}}}} = TestRunner.find_or_start_game("one")
    end
  end
end
