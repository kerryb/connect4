defmodule Connect4.Game.RunnerTest do
  use Connect4.DataCase, async: false

  alias Connect4.Game.Runner
  alias Connect4.Game.Schema.Game
  alias Connect4.GameRegistry
  alias Connect4.Repo
  alias Ecto.Adapters.SQL.Sandbox
  alias Phoenix.PubSub

  setup do
    {:ok, pid} = start_supervised(Runner)
    Sandbox.allow(Repo, self(), pid)
    player_1 = insert(:player, code: "one")
    player_2 = insert(:player, code: "two")
    %{player_1_id: player_1.id, player_2_id: player_2.id}
  end

  describe "Connect4.Game.Runner.start_game/3" do
    test "inserts a game in the database", %{player_1_id: player_1_id, player_2_id: player_2_id} do
      Runner.start_game("one", "two")

      assert [%{player_o_id: ^player_1_id, player_x_id: ^player_2_id, winner: nil}] = Repo.all(Game)
    end

    test "creates a game server" do
      {:ok, id} = Runner.start_game("one", "two")
      assert [{_pid, nil}] = Registry.lookup(GameRegistry, id)
    end

    test "passes the timeout to the game" do
      PubSub.subscribe(Connect4.PubSub, "games")
      {:ok, game_id} = Runner.start_game("one", "two", 50)
      {:ok, _player, _game} = Runner.play("one", "3")
      {:ok, _player, _game} = Runner.play("two", "3")
      Process.sleep(110)
      assert_receive {:completed, %{id: ^game_id}}
    end

    test "updates the database when a game finishes" do
      {:ok, game_id} = Runner.start_game("one", "two")
      PubSub.subscribe(Connect4.PubSub, "runner")

      game =
        Game
        |> Repo.get(game_id)
        |> Map.merge(%{board: %{0 => %{0 => :O}}, winner: "tie"})

      PubSub.broadcast!(Connect4.PubSub, "games", {:completed, game})
      assert_receive {:game_finished, %{id: ^game_id}}
      assert [%{winner: "tie", board: %{0 => %{0 => :O}}}] = Repo.all(Game)
    end
  end

  describe "Connect4.Game.Runner.play/2" do
    test "returns the player and the updated game" do
      {:ok, _id} = Runner.start_game("one", "two")
      assert {:ok, :O, %{next_player: :X, board: %{3 => %{0 => :O}}}} = Runner.play("one", "3")
    end

    test "returns an error if the game is not found" do
      assert {:error, "Game not found"} = Runner.play("one", "3")
    end

    test "passes on any error from the game" do
      {:ok, _id} = Runner.start_game("one", "two")
      assert {:error, "Not your turn"} = Runner.play("two", "3")
    end
  end

  describe "Connect4.Game.Runner.find_game/1" do
    test "returns an in-progress game if found" do
      {:ok, _id} = Runner.start_game("one", "two")
      {:ok, _player, _game} = Runner.play("one", "3")
      assert {:ok, :O, %{board: %{3 => %{0 => :O}}}} = Runner.find_game("one")
    end

    test "returns an error if the game is not found" do
      assert {:error, "Game not found"} = Runner.find_game("one")
    end
  end
end
