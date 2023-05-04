defmodule Connect4Web.GameControllerTest do
  use Connect4Web.ConnCase

  import Connect4.Factory

  alias Connect4.Game.Runner

  setup do
    insert(:player, code: "one")
    insert(:player, code: "two")
    :ok
  end

  describe "GET /game/:code" do
    test "returns the current game for the player with the code, if found", %{conn: conn} do
      Runner.start_game("one", "two", nil)
      conn = get(conn, ~p"/games/one")
      assert %{"playing_as" => "O"} = json_response(conn, 200)
    end

    test "returns an error if the game isn’t found", %{conn: conn} do
      conn = get(conn, ~p"/games/one")
      assert %{"error" => "Game not found"} = json_response(conn, 404)
    end
  end
end
