defmodule Connect4.Game.GameTest do
  use ExUnit.Case, async: true

  alias Connect4.Game.Game
  alias Connect4.GameRegistry
  alias Connect4.Repo
  alias Ecto.Adapters.SQL.Sandbox
  alias Phoenix.PubSub

  @game_id 123

  setup do
    Application.ensure_all_started(:connect4)
    {:ok, pid} = start_supervised({Game, timeout: 100, id: @game_id})
    Sandbox.allow(Repo, self(), pid)
    :ok
  end

  describe "Connect4.Game.Game" do
    test "starts with O’s turn" do
      assert Game.get(@game_id).next_player == :O
    end

    test "alternates players’ turns" do
      {:ok, _game} = play_move(:O, 0)
      assert Game.get(@game_id).next_player == :X
      {:ok, _game} = play_move(:X, 0)
      assert Game.get(@game_id).next_player == :O
    end

    test "allows playing as both players in test mode" do
      {:ok, _game} = play_move(:test, 0)
      assert Game.get(@game_id).next_player == :X
      {:ok, _game} = play_move(:test, 0)
      assert Game.get(@game_id).next_player == :O
    end

    test "keeps track of moves" do
      play_moves(O: 3, X: 2)
      {:ok, game} = play_move(:O, 2)
      assert game.board == %{2 => %{0 => :X, 1 => :O}, 3 => %{0 => :O}}
    end

    test "allows a game to be queried" do
      play_move(:O, 3)
      game = Game.get(@game_id)
      assert game.board == %{3 => %{0 => :O}}
    end

    test "detects four in a row horizontally as a win" do
      game = play_moves(O: 2, X: 2, O: 3, X: 3, O: 0, X: 0, O: 1)
      assert game.winner == :O
    end

    test "detects four in a row vertically as a win" do
      game = play_moves(O: 2, X: 0, O: 2, X: 0, O: 2, X: 0, O: 2)
      assert game.winner == :O
    end

    test "detects four in a row diagonally to the left as a win" do
      game = play_moves(O: 3, X: 2, O: 2, X: 1, O: 1, X: 0, O: 1, X: 0, O: 0, X: 4, O: 0)
      assert game.winner == :O
    end

    test "detects four in a row diagonally to the right as a win" do
      game = play_moves(O: 0, X: 1, O: 1, X: 2, O: 2, X: 3, O: 2, X: 3, O: 3, X: 6, O: 3)
      assert game.winner == :O
    end

    test "is a tie if the board is filled with no lines being made" do
      play_moves(O: 0, X: 0, O: 0, X: 0, O: 0, X: 0)
      play_moves(O: 1, X: 1, O: 1, X: 1, O: 1, X: 1)
      play_moves(O: 2, X: 2, O: 2, X: 2, O: 2, X: 2)
      play_moves(O: 4, X: 3, O: 3, X: 3, O: 3, X: 3, O: 3)
      play_moves(X: 4, O: 4, X: 4, O: 4, X: 4)
      play_moves(O: 5, X: 5, O: 5, X: 5, O: 5, X: 5)
      game = play_moves(O: 6, X: 6, O: 6, X: 6, O: 6, X: 6)
      assert game.winner == :tie
    end

    test "does not allow play out of turn" do
      assert {:error, "Not your turn"} = play_move(:X, 0)
    end

    test "does not allow play in an invalid column" do
      assert {:error, "Column must be 0..6"} = play_move(:O, -1)
      assert {:error, "Column must be 0..6"} = play_move(:O, 7)
      assert {:error, "Column must be 0..6"} = play_move(:O, "foo")
    end

    test "does not allow play in a full column" do
      play_moves(O: 0, X: 0, O: 0, X: 0, O: 0, X: 0)
      assert {:error, "Column is full"} = play_move(:O, 0)
    end

    test "returns an error if attempting to query a game that is not running" do
      assert {:error, :not_found} = Game.get("456")
    end

    test "returns an error if attempting to play in a game that is not running" do
      assert {:error, :not_found} = Game.play("456", :O, "0")
    end

    test "broadcasts a message and terminates on completion" do
      PubSub.subscribe(Connect4.PubSub, "games")
      [{game_pid, _name}] = Registry.lookup(GameRegistry, @game_id)
      Process.monitor(game_pid)
      game = play_moves(O: 2, X: 2, O: 3, X: 3, O: 0, X: 0, O: 1)
      assert_receive {:completed, ^game}
      assert_receive {:DOWN, _ref, :process, ^game_pid, :normal}
    end

    test "switches to the other player if a player doesn’t make a move within <timeout> ms" do
      play_moves(O: 2, X: 2)
      Process.sleep(110)
      assert Game.get(@game_id).next_player == :X
      play_moves(X: 4, O: 4)
      Process.sleep(110)
      assert Game.get(@game_id).next_player == :O
    end

    test "does not apply the timeout to either player’s first move" do
      Process.sleep(110)
      assert Game.get(@game_id).next_player == :O
      play_move(:O, 0)
      Process.sleep(110)
      assert Game.get(@game_id).next_player == :X
    end

    test "allows one player to keep making consecutive moves if their opponent times out" do
      PubSub.subscribe(Connect4.PubSub, "games")
      play_moves(O: 0, X: 1, O: 0)
      Process.sleep(110)
      {:ok, _game} = play_move(:O, 0)
      Process.sleep(110)
      {:ok, game} = play_move(:O, 0)
      assert game.winner == :O
      assert_receive {:completed, ^game}
    end

    test "considers the game a tie if both players time out consecutively" do
      PubSub.subscribe(Connect4.PubSub, "games")
      play_moves(O: 0, X: 0)
      Process.sleep(210)
      %{id: game_id} = game = Game.get(@game_id)
      assert game.winner == :tie
      assert_receive {:completed, %{id: ^game_id}}
    end

    test "resets the timeout each time a move is played" do
      Process.sleep(60)
      {:ok, _game} = play_move(:O, 0)
      Process.sleep(60)
      {:ok, _game} = play_move(:X, 0)
      Process.sleep(60)
      {:ok, _game} = play_move(:O, 0)
      Process.sleep(110)
      assert Game.get(@game_id).next_player == :O
    end

    defp play_moves(moves) do
      Enum.reduce(moves, nil, fn {player, column}, _acc ->
        {:ok, game} = play_move(player, column)
        game
      end)
    end

    defp play_move(player, column), do: Game.play(@game_id, player, to_string(column))
  end

  describe "Inspect implementation for Connect4.Game.Game" do
    test "renders the game of the board and the next player when in progress" do
      assert inspect(%Game{
               id: @game_id,
               next_player: :X,
               board: %{2 => %{0 => :X, 1 => :O}, 3 => %{0 => :O}}
             }) ==
               String.trim("""
               . . . . . . .
               . . . . . . .
               . . . . . . .
               . . . . . . .
               . . O . . . .
               . . X O . . .
               (X to play)
               """)
    end

    test "renders the game of the board and the winner when complete" do
      assert inspect(%Game{
               id: @game_id,
               next_player: :X,
               board: %{
                 0 => %{0 => :O, 1 => :X},
                 1 => %{0 => :O, 1 => :X},
                 2 => %{0 => :O, 1 => :X},
                 3 => %{0 => :O}
               },
               winner: :O
             }) ==
               String.trim("""
               . . . . . . .
               . . . . . . .
               . . . . . . .
               . . . . . . .
               X X X . . . .
               O O O O . . .
               (O has won)
               """)
    end
  end
end
