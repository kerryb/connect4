defmodule Connect4.Auth.Queries.PlayerQueriesTest do
  use Connect4.DataCase, async: true

  import Assertions, only: [assert_lists_equal: 3]

  alias Connect4.Auth.Queries.PlayerQueries
  alias Connect4.Auth.Schema.Player

  describe "Connect4.Game.Queries.GameQueries.active/0" do
    test "returns all confirmed non-admin players" do
      player_1 = insert(:player, confirmed_at: DateTime.utc_now())
      _player_2 = insert(:player, confirmed_at: nil)
      player_3 = insert(:player, confirmed_at: DateTime.utc_now())
      _admin = insert(:player, confirmed_at: DateTime.utc_now(), admin: true)

      assert_lists_equal(
        [player_1, player_3],
        PlayerQueries.active(),
        &(&1.id == &2.id)
      )
    end
  end

  describe "Connect4.Game.Queries.GameQueries.active_with_games/0" do
    test "returns all confirmed non-admin players" do
      player_1 = insert(:player, confirmed_at: DateTime.utc_now())
      _player_2 = insert(:player, confirmed_at: nil)
      player_3 = insert(:player, confirmed_at: DateTime.utc_now())
      _admin = insert(:player, confirmed_at: DateTime.utc_now(), admin: true)

      assert_lists_equal(
        [player_1, player_3],
        PlayerQueries.active_with_games(),
        &(&1.id == &2.id)
      )
    end

    test "preloads games and each game’s O and X players" do
      player_1 = insert(:player, confirmed_at: DateTime.utc_now())
      player_2 = insert(:player, confirmed_at: DateTime.utc_now())
      insert(:game, player_o: player_1, player_x: player_2, winner: "O")
      players = PlayerQueries.active_with_games()

      assert %{games_as_o: [%{player_o: %Player{}, player_x: %Player{}}], games_as_x: []} =
               Enum.find(players, &(&1.id == player_1.id))
    end
  end

  describe "Connect4.Game.Queries.GameQueries.from_code/1" do
    test "returns the player with the code" do
      %{id: id} = insert(:player, code: "ABCDE")
      assert %{id: ^id} = PlayerQueries.from_code("ABCDE")
    end

    test "returns nil if the code is not found" do
      assert is_nil(PlayerQueries.from_code("ABCDE"))
    end
  end

  describe "Connect4.Game.Queries.GameQueries.reload_player_with_game_and_stats/1" do
    test "reloads the player, with games and stats" do
      player_1 = insert(:player, confirmed_at: DateTime.utc_now())
      player_2 = insert(:player, confirmed_at: DateTime.utc_now())
      insert(:game, player_o: player_1, player_x: player_2, winner: "O")

      assert %{games_as_o: [_game], games_as_x: [], played: 1} =
               PlayerQueries.reload_player_with_game_and_stats(player_1.id)
    end
  end

  describe "Connect4.Game.Queries.GameQueries.regenerate_code/1" do
    test "generates a new player code" do
      player = insert(:player)
      PlayerQueries.regenerate_code(player)
      refute player.code == Repo.reload!(player).code
    end
  end
end
