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
      {:ok, _game} = Game.play(game, :player_1, 0)
      assert Game.next_player(game) == :player_2
    end

    test "is player 1’s turn after player 2 plays", %{game: game} do
      {:ok, _game} = Game.play(game, :player_1, 0)
      {:ok, _game} = Game.play(game, :player_2, 0)
      assert Game.next_player(game) == :player_1
    end

    test "does not allow play out of turn", %{game: game} do
      assert {:error, "Not your turn"} = Game.play(game, :player_2, 0)
    end
  end
end
