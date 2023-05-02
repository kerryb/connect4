defmodule Connect4.GameTest do
  use ExUnit.Case, async: true

  alias Connect4.Game

  setup do
    {:ok, game} = start_supervised(Game)
    %{game: game}
  end

  describe "Connect4.Game" do
    test "starts with O’s turn", %{game: game} do
      assert Game.next_player(game) == :O
    end

    test "alternates players’ turns", %{game: game} do
      {:ok, _game} = Game.play(game, :O, 0)
      assert Game.next_player(game) == :X
      {:ok, _game} = Game.play(game, :X, 0)
      assert Game.next_player(game) == :O
    end

    test "does not allow play out of turn", %{game: game} do
      assert {:error, "Not your turn"} = Game.play(game, :X, 0)
    end

    test "keeps track of moves", %{game: game} do
      {:ok, _game} = Game.play(game, :O, 3)
      {:ok, _game} = Game.play(game, :X, 2)
      {:ok, game} = Game.play(game, :O, 2)
      assert game.board == %{2 => %{0 => :X, 1 => :O}, 3 => %{0 => :O}}
    end

    test "detects four in a row horizontally as a win", %{game: game} do
      {:ok, _game} = Game.play(game, :O, 2)
      {:ok, _game} = Game.play(game, :X, 2)
      {:ok, _game} = Game.play(game, :O, 3)
      {:ok, _game} = Game.play(game, :X, 3)
      {:ok, _game} = Game.play(game, :O, 0)
      {:ok, _game} = Game.play(game, :X, 0)
      {:ok, game} = Game.play(game, :O, 1)
      assert game.winner == :O
    end

    test "detects four in a row vertically as a win", %{game: game} do
      {:ok, _game} = Game.play(game, :O, 2)
      {:ok, _game} = Game.play(game, :X, 0)
      {:ok, _game} = Game.play(game, :O, 2)
      {:ok, _game} = Game.play(game, :X, 0)
      {:ok, _game} = Game.play(game, :O, 2)
      {:ok, _game} = Game.play(game, :X, 0)
      {:ok, game} = Game.play(game, :O, 2)
      assert game.winner == :O
    end

    test "detects four in a row diagonally to the left as a win", %{game: game} do
      {:ok, _game} = Game.play(game, :O, 3)
      {:ok, _game} = Game.play(game, :X, 2)
      {:ok, _game} = Game.play(game, :O, 2)
      {:ok, _game} = Game.play(game, :X, 1)
      {:ok, _game} = Game.play(game, :O, 1)
      {:ok, _game} = Game.play(game, :X, 0)
      {:ok, _game} = Game.play(game, :O, 1)
      {:ok, _game} = Game.play(game, :X, 0)
      {:ok, _game} = Game.play(game, :O, 0)
      {:ok, _game} = Game.play(game, :X, 4)
      {:ok, game} = Game.play(game, :O, 0)
      assert game.winner == :O
    end

    test "detects four in a row diagonally to the right as a win", %{game: game} do
      {:ok, _game} = Game.play(game, :O, 0)
      {:ok, _game} = Game.play(game, :X, 1)
      {:ok, _game} = Game.play(game, :O, 1)
      {:ok, _game} = Game.play(game, :X, 2)
      {:ok, _game} = Game.play(game, :O, 2)
      {:ok, _game} = Game.play(game, :X, 3)
      {:ok, _game} = Game.play(game, :O, 2)
      {:ok, _game} = Game.play(game, :X, 3)
      {:ok, _game} = Game.play(game, :O, 3)
      {:ok, _game} = Game.play(game, :X, 6)
      {:ok, game} = Game.play(game, :O, 3)
      assert game.winner == :O
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
