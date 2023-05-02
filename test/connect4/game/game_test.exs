defmodule Connect4.GameTest do
  use ExUnit.Case, async: true

  alias Connect4.Game

  setup do
    {:ok, game} = start_supervised(Game)
    %{game: game}
  end

  describe "Connect4.Game" do
    test "is initially in the :player_1_to_play state", %{game: game} do
      assert Game.state(game) == :player_1_to_play
    end
  end
end
