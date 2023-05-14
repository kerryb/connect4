defmodule Connect4.Game.Queries.GameQueriesTest do
  use Connect4.DataCase, async: true

  alias Connect4.Game.Queries.GameQueries
  alias Connect4.Game.Schema.Game
  alias Connect4.Repo

  describe "Connect4.Game.Queries.GameQueries.insert_from_codes/2" do
    test "inserts a Game record with an empty board" do
      %{id: player_1_id} = insert(:player, code: "one")
      %{id: player_2_id} = insert(:player, code: "two")
      {:ok, _game} = GameQueries.insert_from_codes("one", "two")

      assert [%{player_o_id: ^player_1_id, player_x_id: ^player_2_id, board: %{}, winner: nil}] = Repo.all(Game)
    end
  end

  describe "Connect4.Game.Queries.GameQueries.update_winner/2" do
    test "saves the board, and sets the winner to the player with the supplied code" do
      player_1 = insert(:player, code: "one")
      %{id: game_id} = insert(:game, player_o: player_1)
      board = %{0 => %{0 => :O, 1 => :O, 2 => :O, 3 => :O}, 1 => %{0 => :X, 2 => :X, 3 => :X}}
      GameQueries.update_winner(game_id, :O, board)
      assert [%{winner: "O", board: ^board}] = Repo.all(Game)
    end

    test "returns an error if the game is not found" do
      assert {:error, "Game not found"} = GameQueries.update_winner(123, :O, %{})
    end
  end
end
