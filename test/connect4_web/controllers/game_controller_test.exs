defmodule Connect4Web.GameControllerTest do
  use Connect4Web.ConnCase, async: true

  alias Connect4.Game.Runner
  alias Connect4.Repo
  alias Ecto.Adapters.SQL.Sandbox

  setup do
    {:ok, pid} = start_supervised(Runner)
    Sandbox.allow(Repo, self(), pid)
    %{code: code_1} = insert(:player)
    %{code: code_2} = insert(:player)
    %{code_1: code_1, code_2: code_2}
  end

  describe "GET /game/:code" do
    test "returns the current game for the player with the code, if found", %{
      conn: conn,
      code_1: code_1,
      code_2: code_2
    } do
      Runner.start_game(code_1, code_2)
      conn = get(conn, ~p"/games/#{code_1}")
      assert %{"playing_as" => "O"} = json_response(conn, 200)
    end

    test "returns a 404 error if the game isn’t found", %{conn: conn} do
      conn = get(conn, ~p"/games/non-existent-code")
      assert %{"error" => "Game not found"} = json_response(conn, 404)
    end
  end

  describe "POST /game/:code/:column" do
    test "plays a turn", %{conn: conn, code_1: code_1, code_2: code_2} do
      Runner.start_game(code_1, code_2)
      conn = post(conn, ~p"/games/#{code_1}/0")

      assert %{"next_player" => "X", "board" => %{"0" => %{"0" => "O"}}} = json_response(conn, 200)
    end

    test "returns any error from the game", %{conn: conn, code_1: code_1, code_2: code_2} do
      Runner.start_game(code_1, code_2)
      conn = post(conn, ~p"/games/#{code_2}/0")
      assert %{"error" => "Not your turn"} = json_response(conn, 400)
    end
  end
end
