defmodule Connect4.GameTest do
  use ExUnit.Case, async: true

  alias Connect4.Game

  @game_id 123

  setup do
    {:ok, _game} = start_supervised({Game, @game_id})
    :ok
  end

  describe "Connect4.Game" do
    test "starts with O’s turn" do
      assert Game.next_player(@game_id) == :O
    end

    test "alternates players’ turns" do
      {:ok, _} = Game.play(@game_id, :O, 0)
      assert Game.next_player(@game_id) == :X
      {:ok, _} = Game.play(@game_id, :X, 0)
      assert Game.next_player(@game_id) == :O
    end

    test "keeps track of moves" do
      {:ok, _} = Game.play(@game_id, :O, 3)
      {:ok, _} = Game.play(@game_id, :X, 2)
      {:ok, state} = Game.play(@game_id, :O, 2)
      assert state.board == %{2 => %{0 => :X, 1 => :O}, 3 => %{0 => :O}}
    end

    test "detects four in a row horizontally as a win" do
      {:ok, _} = Game.play(@game_id, :O, 2)
      {:ok, _} = Game.play(@game_id, :X, 2)
      {:ok, _} = Game.play(@game_id, :O, 3)
      {:ok, _} = Game.play(@game_id, :X, 3)
      {:ok, _} = Game.play(@game_id, :O, 0)
      {:ok, _} = Game.play(@game_id, :X, 0)
      {:ok, state} = Game.play(@game_id, :O, 1)
      assert state.winner == :O
    end

    test "detects four in a row vertically as a win" do
      {:ok, _} = Game.play(@game_id, :O, 2)
      {:ok, _} = Game.play(@game_id, :X, 0)
      {:ok, _} = Game.play(@game_id, :O, 2)
      {:ok, _} = Game.play(@game_id, :X, 0)
      {:ok, _} = Game.play(@game_id, :O, 2)
      {:ok, _} = Game.play(@game_id, :X, 0)
      {:ok, state} = Game.play(@game_id, :O, 2)
      assert state.winner == :O
    end

    test "detects four in a row diagonally to the left as a win" do
      {:ok, _} = Game.play(@game_id, :O, 3)
      {:ok, _} = Game.play(@game_id, :X, 2)
      {:ok, _} = Game.play(@game_id, :O, 2)
      {:ok, _} = Game.play(@game_id, :X, 1)
      {:ok, _} = Game.play(@game_id, :O, 1)
      {:ok, _} = Game.play(@game_id, :X, 0)
      {:ok, _} = Game.play(@game_id, :O, 1)
      {:ok, _} = Game.play(@game_id, :X, 0)
      {:ok, _} = Game.play(@game_id, :O, 0)
      {:ok, _} = Game.play(@game_id, :X, 4)
      {:ok, state} = Game.play(@game_id, :O, 0)
      assert state.winner == :O
    end

    test "detects four in a row diagonally to the right as a win" do
      {:ok, _} = Game.play(@game_id, :O, 0)
      {:ok, _} = Game.play(@game_id, :X, 1)
      {:ok, _} = Game.play(@game_id, :O, 1)
      {:ok, _} = Game.play(@game_id, :X, 2)
      {:ok, _} = Game.play(@game_id, :O, 2)
      {:ok, _} = Game.play(@game_id, :X, 3)
      {:ok, _} = Game.play(@game_id, :O, 2)
      {:ok, _} = Game.play(@game_id, :X, 3)
      {:ok, _} = Game.play(@game_id, :O, 3)
      {:ok, _} = Game.play(@game_id, :X, 6)
      {:ok, state} = Game.play(@game_id, :O, 3)
      assert state.winner == :O
    end

    test "does not allow play out of turn" do
      assert {:error, "Not your turn"} = Game.play(@game_id, :X, 0)
    end

    test "does not allow play in an invalid column" do
      assert {:error, "Column must be 0..6"} = Game.play(@game_id, :O, -1)
      assert {:error, "Column must be 0..6"} = Game.play(@game_id, :O, 7)
      assert {:error, "Column must be 0..6"} = Game.play(@game_id, :O, "foo")
    end

    test "does not allow play in a full column" do
      {:ok, _} = Game.play(@game_id, :O, 0)
      {:ok, _} = Game.play(@game_id, :X, 0)
      {:ok, _} = Game.play(@game_id, :O, 0)
      {:ok, _} = Game.play(@game_id, :X, 0)
      {:ok, _} = Game.play(@game_id, :O, 0)
      {:ok, _} = Game.play(@game_id, :X, 0)
      assert {:error, "Column is full"} = Game.play(@game_id, :O, 0)
    end
  end

  describe "Inspect implementation for Connect4.Game" do
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
