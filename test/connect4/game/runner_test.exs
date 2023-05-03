defmodule Connect4.Game.RunnerTest do
  use Connect4.DataCase, async: true

  alias Connect4.Game.Runner
  alias Connect4.Game.Schema.Game
  alias Connect4.Repo

  setup do
    start_supervised!(Runner, id: :test_runner)
    player_1 = insert(:player, code: "foo")
    player_2 = insert(:player, code: "bar")
    %{player_1_id: player_1.id, player_2_id: player_2.id}
  end

  describe "Connect4.Game.Runner" do
    test "saves a new game to the database", %{player_1_id: player_1_id, player_2_id: player_2_id} do
      Runner.start_game("foo", "bar")

      assert [%{player_o_id: player_1_id, player_x_id: player_2_id, winner_id: nil}] =
               Repo.all(Game)
    end
  end
end
