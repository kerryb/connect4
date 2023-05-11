# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Connect4Web.TestController do
  use Connect4Web, :controller

  alias Connect4.Auth.Queries.PlayerQueries
  alias Connect4.Game.TestRunner
  alias Connect4Web.GameJSON

  def show(conn, %{"code" => code}) do
    if PlayerQueries.from_code(code) do
      find_or_start(conn, code)
    else
      conn
      |> put_status(:not_found)
      |> json(%{error: "Game not found"})
    end
  end

  defp find_or_start(conn, code) do
    case TestRunner.find_or_start_game(code) do
      {:ok, game} ->
        json(conn, GameJSON.render(game, game.next_player))

      {:error, message} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: message})
    end
  end

  def play(conn, %{"code" => code, "column" => column}) do
    if PlayerQueries.from_code(code) do
      play_or_start(conn, code, column)
    else
      conn
      |> put_status(:not_found)
      |> json(%{error: "Game not found"})
    end
  end

  defp play_or_start(conn, code, column) do
    case TestRunner.play(code, column) do
      {:ok, game} ->
        json(conn, GameJSON.render(game, game.next_player))

      {:error, message} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: message})
    end
  end
end
