defmodule Connect4Web.GameControllerTest do
  use Connect4Web.ConnCase

  import Connect4.Factory

  alias Connect4.Game.Runner
  alias Connect4.Repo
  alias Ecto.Adapters.SQL.Sandbox

  setup do
    {:ok, pid} = start_supervised(Runner)
    Sandbox.allow(Repo, self(), pid)
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
      conn = get(conn, ~p"/games/non-existent-code")
      assert %{"error" => "Game not found"} = json_response(conn, 404)
    end
  end
end
