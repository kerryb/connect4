defmodule Connect4.Auth.Queries.PlayerQueriesTest do
  use Connect4.DataCase, async: true

  import Assertions, only: [assert_lists_equal: 3]

  alias Connect4.Auth.Queries.PlayerQueries
  alias Connect4.Repo

  describe "Connect4.Game.Queries.GameQueries.all/0" do
    test "returns all players" do
      player_1 = insert(:player, code: "one")
      player_2 = insert(:player, code: "two")
      assert_lists_equal([player_1, player_2], PlayerQueries.all(), &(&1.id == &2.id))
    end
  end
end
