defmodule Connect4.Game.GameTest do
  use ExUnit.Case, async: true

  alias Connect4.Game.Game
  alias Phoenix.PubSub

  @game_id 123

  setup do
    start_supervised!({Game, id: @game_id})
    :ok
  end

  describe "Connect4.Game.Game" do
    test "starts with O’s turn" do
      assert Game.next_player(@game_id) == :O
    end

    test "alternates players’ turns" do
      {:ok, _} = play_move(:O, 0)
      assert Game.next_player(@game_id) == :X
      {:ok, _} = play_move(:X, 0)
      assert Game.next_player(@game_id) == :O
    end

    test "keeps track of moves" do
      play_moves(O: 3, X: 2)
      {:ok, state} = play_move(:O, 2)
      assert state.board == %{2 => %{0 => :X, 1 => :O}, 3 => %{0 => :O}}
    end

    test "detects four in a row horizontally as a win" do
      state = play_moves(O: 2, X: 2, O: 3, X: 3, O: 0, X: 0, O: 1)
      assert state.winner == :O
    end

    test "detects four in a row vertically as a win" do
      state = play_moves(O: 2, X: 0, O: 2, X: 0, O: 2, X: 0, O: 2)
      assert state.winner == :O
    end

    test "detects four in a row diagonally to the left as a win" do
      state = play_moves(O: 3, X: 2, O: 2, X: 1, O: 1, X: 0, O: 1, X: 0, O: 0, X: 4, O: 0)
      assert state.winner == :O
    end

    test "detects four in a row diagonally to the right as a win" do
      state = play_moves(O: 0, X: 1, O: 1, X: 2, O: 2, X: 3, O: 2, X: 3, O: 3, X: 6, O: 3)
      assert state.winner == :O
    end

    test "is a tie if the board is filled with no lines being made" do
      play_moves(O: 0, X: 0, O: 0, X: 0, O: 0, X: 0)
      play_moves(O: 1, X: 1, O: 1, X: 1, O: 1, X: 1)
      play_moves(O: 2, X: 2, O: 2, X: 2, O: 2, X: 2)
      play_moves(O: 4, X: 3, O: 3, X: 3, O: 3, X: 3, O: 3)
      play_moves(X: 4, O: 4, X: 4, O: 4, X: 4)
      play_moves(O: 5, X: 5, O: 5, X: 5, O: 5, X: 5)
      state = play_moves(O: 6, X: 6, O: 6, X: 6, O: 6, X: 6)
      assert state.winner == :tie
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

    test "broadcasts a message on completion" do
      PubSub.subscribe(Connect4.PubSub, "games")
      %{board: board} = play_moves(O: 2, X: 2, O: 3, X: 3, O: 0, X: 0, O: 1)
      assert_receive {:completed, :O, ^board}
    end

    test "when a timeout is given, defaults if a player doesn’t make a move in that number of ms" do
      PubSub.subscribe(Connect4.PubSub, "games")
      stop_supervised!(Game)
      start_supervised!({Game, id: "timeout-test", timeout: 100})
      Process.sleep(110)
      assert_received {:completed, :X, _board}
    end

    test "resets the timeout each time a move is played" do
      PubSub.subscribe(Connect4.PubSub, "games")
      stop_supervised!(Game)
      start_supervised!({Game, id: "timeout-test", timeout: 100})
      Process.sleep(60)
      {:ok, _} = Game.play("timeout-test", :O, 0)
      Process.sleep(60)
      {:ok, _} = Game.play("timeout-test", :X, 0)
      Process.sleep(60)
      {:ok, _} = Game.play("timeout-test", :O, 0)
      Process.sleep(110)
      assert_received {:completed, :O, _board}
    end

    defp play_moves(moves) do
      Enum.reduce(moves, nil, fn {player, column}, _ ->
        {:ok, state} = play_move(player, column)
        state
      end)
    end

    defp play_move(player, column), do: Game.play(@game_id, player, column)
  end

  describe "Inspect implementation for Connect4.Game.Game" do
    test "renders the state of the board and the next player when in progress" do
      assert inspect(%Game{next_player: :X, board: %{2 => %{0 => :X, 1 => :O}, 3 => %{0 => :O}}}) ==
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

    test "renders the state of the board and the winner when complete" do
      assert inspect(%Game{
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
