defmodule Connect4.Game.RunnerTest do
  use Connect4.DataCase

  alias Connect4.Game.Runner
  alias Connect4.Game.Schema.Game
  alias Connect4.{GameRegistry, Repo}
  alias Ecto.Adapters.SQL.Sandbox
  alias Phoenix.PubSub

  setup do
    {:ok, pid} = start_supervised(Runner)
    Sandbox.allow(Repo, self(), pid)
    player_1 = insert(:player, code: "one")
    player_2 = insert(:player, code: "two")
    %{player_1_id: player_1.id, player_2_id: player_2.id}
  end

  describe "Connect4.Game.Runner" do
    test "saves a new game to the database", %{player_1_id: player_1_id, player_2_id: player_2_id} do
      Runner.start_game("one", "two")

      assert [%{player_o_id: ^player_1_id, player_x_id: ^player_2_id, winner_id: nil}] =
               Repo.all(Game)
    end

    test "creates a game server" do
      {:ok, id} = Runner.start_game("one", "two")
      assert [{_pid, nil}] = Registry.lookup(GameRegistry, id)
    end

    test "passes the timeout to the game" do
      PubSub.subscribe(Connect4.PubSub, "games")
      {:ok, id} = Runner.start_game("one", "two", 100)
      Process.sleep(50)
      assert_receive {:completed, ^id, :X, %{}}
    end

    test "returns the player and the updated game when a turn is played" do
      {:ok, _id} = Runner.start_game("one", "two")
      assert {:ok, :O, %{next_player: :X, board: %{3 => %{0 => :O}}}} = Runner.play("one", 3)

      assert {:ok, :X, %{next_player: :O, board: %{3 => %{0 => :O, 1 => :X}}}} =
               Runner.play("two", 3)
    end

    test "allows an in-progress game to be queried" do
      {:ok, _id} = Runner.start_game("one", "two")
      {:ok, _, _} = Runner.play("one", 3)
      assert {:ok, :O, %{board: %{3 => %{0 => :O}}}} = Runner.find_game("one")
    end

    test "returns an error if querying a non-existent game" do
      assert {:error, "Game not found"} = Runner.find_game("one")
    end

    test "updates the database when a game finishes", %{player_1_id: player_1_id} do
      {:ok, id} = Runner.start_game("one", "two")

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
