defmodule Connect4Web.GameJSONTest do
  use ExUnit.Case, async: true

  alias Connect4.Game.Game
  alias Connect4Web.GameJSON

  describe "Connect4Web.GameJSON.render/2" do
    setup do
      game = %Game{id: 123, next_player: :O, board: %{0 => %{0 => :O, 1 => :X}, 3 => %{0 => :O}}}
      %{game: game}
    end

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
  end
end
