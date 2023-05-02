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
  end
end
