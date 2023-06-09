defmodule Connect4.Auth.Schema.PlayerTest do
  use Connect4.DataCase, async: true

  import Connect4.Factory

  alias Connect4.Auth.Schema.Player

  describe "Connect4.Auth.Schema.Player.calculate_stats/1" do
    test "populates virtual fields from preloaded :games_as_o and :games_as_x associations" do
      player_1 = insert(:player, confirmed_at: DateTime.utc_now())
      player_2 = insert(:player, confirmed_at: DateTime.utc_now())
      insert(:game, player_o: player_1, player_x: player_2, winner: "O")
      insert(:game, player_o: player_2, player_x: player_1, winner: "O")
      insert(:game, player_o: player_2, player_x: player_1, winner: "tie")
      insert(:game, player_o: player_1, player_x: player_2, winner: nil)

      assert %{played: 3, won: 1, tied: 1, lost: 1, points: 4} = Player.calculate_stats(player_1)
    end

    test "also preloads both players for each game" do
      player_1 = insert(:player, confirmed_at: DateTime.utc_now())
      player_2 = insert(:player, confirmed_at: DateTime.utc_now())
      insert(:game, player_o: player_1, player_x: player_2, winner: "O")

      assert %{games_as_o: [%{player_o: %Player{}, player_x: %Player{}}], games_as_x: []} =
               Player.calculate_stats(player_1)
    end
  end
end
