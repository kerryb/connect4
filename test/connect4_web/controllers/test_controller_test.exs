defmodule Connect4Web.TestControllerTest do
  use Connect4Web.ConnCase, async: false

  alias Connect4.Game.TestRunner
  alias Connect4.Repo
  alias Ecto.Adapters.SQL.Sandbox

  setup do
    {:ok, pid} = start_supervised(TestRunner)
    Sandbox.allow(Repo, self(), pid)
    %{code: code} = insert(:player)
    %{code: code}
  end

  describe "GET /test/:code" do
    test "starts a new game if necessary", %{conn: conn, code: code} do
      conn = get(conn, ~p"/test/#{code}")
      assert %{"playing_as" => "O"} = json_response(conn, 200)
    end

    test "returns the current test game if already running", %{conn: conn, code: code} do
      TestRunner.play(code, "0")
      conn = get(conn, ~p"/test/#{code}")
      assert %{"playing_as" => "X", "board" => %{"0" => %{"0" => "O"}}} = json_response(conn, 200)
    end

    test "returns a 404 error if the code isn’t found", %{conn: conn} do
      conn = get(conn, ~p"/test/non-existent-code")
      assert %{"error" => "Game not found"} = json_response(conn, 404)
    end
  end

  describe "POST /test/:code/:column" do
    test "plays a turn", %{conn: conn, code: code} do
      TestRunner.play(code, "0")
      conn = post(conn, ~p"/test/#{code}/1")

      assert %{"next_player" => "O", "board" => %{"0" => %{"0" => "O"}, "1" => %{"0" => "X"}}} = json_response(conn, 200)
    end

    test "starts a new game if necessary", %{conn: conn, code: code} do
      conn = post(conn, ~p"/test/#{code}/0")

      assert %{"next_player" => "X", "board" => %{"0" => %{"0" => "O"}}} = json_response(conn, 200)
    end

    test "returns a 404 error if the code isn’t found", %{conn: conn} do
      conn = post(conn, ~p"/test/non-existent-code/8")
      assert %{"error" => "Game not found"} = json_response(conn, 404)
    end

    test "returns any error from the game", %{conn: conn, code: code} do
      conn = post(conn, ~p"/test/#{code}/8")
      assert %{"error" => "Column must be 0..6"} = json_response(conn, 400)
    end
  end
end
