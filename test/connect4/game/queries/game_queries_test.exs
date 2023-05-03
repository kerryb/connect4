defmodule Connect4.Game.Queries.GameQueriesTest do
  use Connect4.DataCase, async: true

  alias Connect4.Game.Queries.GameQueries
  alias Connect4.Game.Schema.Game
  alias Connect4.Repo

  describe "Connect4.Game.Queries.GameQueries.insert_from_codes/2" do
    test "inserts a Game record" do
      %{id: player_1_id} = insert(:player, code: "one")
      %{id: player_2_id} = insert(:player, code: "two")
      {:ok, _} = GameQueries.insert_from_codes("one", "two")

      assert [%{player_o_id: ^player_1_id, player_x_id: ^player_2_id, winner_id: nil}] =
               Repo.all(Game)
    end
  end

  describe "Connect4.Game.Queries.GameQueries.update_winner/2" do
    test "updates the winner to the player with the supplied code" do
      %{id: player_id} = player_1 = insert(:player, code: "one")
      %{id: game_id} = insert(:game, player_o: player_1)
      GameQueries.update_winner(game_id, :O)
      assert [%{winner_id: ^player_id}] = Repo.all(Game)
    end

    test "returns an error if the game is not found" do
      assert {:error, "Game not found"} = GameQueries.update_winner(123, :O)
    end
  end
end
