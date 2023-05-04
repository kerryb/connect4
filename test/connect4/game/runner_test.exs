defmodule Connect4.Game.RunnerTest do
  use Connect4.DataCase, async: true

  alias Connect4.Game.Runner
  alias Connect4.Game.Schema.Game
  alias Connect4.GameRegistry
  alias Connect4.Repo
  alias Ecto.Adapters.SQL.Sandbox
  alias Phoenix.PubSub

  setup do
    {:ok, pid} = start_supervised({Runner, name: :test_runner})
    Sandbox.allow(Repo, self(), pid)

    # Stops global Runner (as opposed to the test-specific one we created
    # above) crashing when it receives a pubsub message
    Sandbox.allow(Repo, self(), Runner)

    player_1 = insert(:player, code: "one")
    player_2 = insert(:player, code: "two")
    %{pid: pid, player_1_id: player_1.id, player_2_id: player_2.id}
  end

  describe "Connect4.Game.Runner" do
    test "saves a new game to the database", %{
      pid: pid,
      player_1_id: player_1_id,
      player_2_id: player_2_id
    } do
      Runner.start_game("one", "two", nil, pid)

      assert [%{player_o_id: ^player_1_id, player_x_id: ^player_2_id, winner_id: nil}] =
               Repo.all(Game)
    end

    test "creates a game server", %{pid: pid} do
      {:ok, id} = Runner.start_game("one", "two", nil, pid)
      assert [{_pid, nil}] = Registry.lookup(GameRegistry, id)
    end

    test "passes the timeout to the game", %{pid: pid} do
      PubSub.subscribe(Connect4.PubSub, "games")
      {:ok, id} = Runner.start_game("one", "two", 100, pid)
      Process.sleep(50)
      assert_receive {:completed, ^id, :X, %{}}
    end

    test "returns the updated game board when a turn is played", %{pid: pid} do
      {:ok, _id} = Runner.start_game("one", "two", nil, pid)
      {:ok, board} = Runner.play("one", 3, pid)
      assert board == %{3 => %{0 => :O}}
      {:ok, board} = Runner.play("two", 3, pid)
      assert board == %{3 => %{0 => :O, 1 => :X}}
    end

    test "allows an in-progress game to be queried", %{pid: pid} do
      {:ok, _id} = Runner.start_game("one", "two", nil, pid)
      {:ok, _board} = Runner.play("one", 3, pid)
      assert {:ok, :O, %{board: %{3 => %{0 => :O}}}} = Runner.find_game("one", pid)
    end

    test "returns an error if querying a non-existent game", %{pid: pid} do
      assert {:error, "Game not found"} = Runner.find_game("one", pid)
    end

    test "updates the database when a game finishes", %{pid: pid, player_1_id: player_1_id} do
      {:ok, id} = Runner.start_game("one", "two", nil, pid)

      PubSub.subscribe(Connect4.PubSub, "tournament")

      PubSub.broadcast!(
        Connect4.PubSub,
        "games",
        {:completed, id, :O,
         %{0 => %{0 => :O, 1 => :O, 2 => :O, 3 => :O}, 1 => %{0 => :X, 2 => :X, 3 => :X}}}
      )

      assert_receive :game_finished
      assert [%{winner_id: ^player_1_id}] = Repo.all(Game)
    end
  end
end
