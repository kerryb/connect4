defmodule Connect4.GameTest do
  use ExUnit.Case, async: true

  alias Connect4.Game

  setup do
    {:ok, game} = start_supervised(Game)
    %{game: game}
  end

  describe "Connect4.Game" do
    test "starts with player 1’s turn", %{game: game} do
      assert Game.next_player(game) == :player_1
    end

    test "is player 2’s turn after player 1 plays", %{game: game} do
      Game.play(game, :player_1, 0)
      assert Game.next_player(game) == :player_2
    end

    test "is in the :player_1_to_play state after player 2 plays", %{game: game} do
      Game.play(game, :player_1, 0)
      Game.play(game, :player_2, 0)
      assert Game.next_player(game) == :player_1
    end
  end
end
