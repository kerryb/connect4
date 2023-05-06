defmodule Connect4.Auth.Queries.PlayerQueriesTest do
  use Connect4.DataCase, async: true

  import Assertions, only: [assert_lists_equal: 3]

  alias Connect4.Auth.Queries.PlayerQueries

  describe "Connect4.Game.Queries.GameQueries.confirmed/0" do
    test "returns all confirmed non-admin players" do
      player_1 = insert(:player, confirmed_at: DateTime.utc_now())
      _player_2 = insert(:player, confirmed_at: nil)
      player_3 = insert(:player, confirmed_at: DateTime.utc_now())
      _admin = insert(:player, confirmed_at: DateTime.utc_now(), admin: true)
      assert_lists_equal([player_1, player_3], PlayerQueries.confirmed(), &(&1.id == &2.id))
    end
  end
end
