defmodule Connect4Web.GameJSONTest do
  use ExUnit.Case, async: true

  alias Connect4.Game.Game
  alias Connect4Web.GameJSON

  setup do
    game = %Game{id: 123, next_player: :O, board: %{0 => %{0 => :O, 1 => :X}, 3 => %{0 => :O}}}
    %{game: game}
  end

  describe "Connect4Web.GameJSON.render/2" do
    test "returns who you’re playing as (O or X)", %{game: game} do
      assert GameJSON.render(game, :X).playing_as == :X
    end

    test "returns the player to play next", %{game: game} do
      assert GameJSON.render(game, :X).next_player == :O
    end

    test "returns the board as an object", %{game: game} do
      assert GameJSON.render(game, :X).board == game.board
    end

    test "returns the board as a nested array", %{game: game} do
      assert GameJSON.render(game, :X).board_as_array == [
               [:O, :X, nil, nil, nil, nil],
               [nil, nil, nil, nil, nil, nil],
               [nil, nil, nil, nil, nil, nil],
               [:O, nil, nil, nil, nil, nil],
               [nil, nil, nil, nil, nil, nil],
               [nil, nil, nil, nil, nil, nil],
               [nil, nil, nil, nil, nil, nil]
             ]
    end

    test "returns the winner", %{game: game} do
      assert GameJSON.render(%{game | winner: :O}, :X).winner == :O
    end

    test "returns a status of 'playing' if the game is still in progress", %{game: game} do
      assert GameJSON.render(game, :O).status == "playing"
    end

    test "returns a status of 'win' if the player won", %{game: game} do
      assert GameJSON.render(%{game | winner: :O}, :O).status == "win"
    end

    test "returns a status of 'lose' if the player won", %{game: game} do
      assert GameJSON.render(%{game | winner: :O}, :X).status == "lose"
    end

    test "returns a status of 'tie' if the game was tied", %{game: game} do
      assert GameJSON.render(%{game | winner: :tie}, :X).status == "tie"
    end
  end
end
