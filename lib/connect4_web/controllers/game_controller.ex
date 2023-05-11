# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Connect4Web.GameController do
  use Connect4Web, :controller

  alias Connect4.Game.Runner
  alias Connect4Web.GameJSON

  def show(conn, %{"code" => code}) do
    case Runner.find_game(code) do
      {:ok, player, game} -> json(conn, GameJSON.render(game, player))
      {:error, message} -> handle_error(conn, message)
    end
  end

  def play(conn, %{"code" => code, "column" => column}) do
    case Runner.play(code, column) do
      {:ok, player, game} -> json(conn, GameJSON.render(game, player))
      {:error, message} -> handle_error(conn, message)
    end
  end

  defp handle_error(conn, :not_found) do
    Process.sleep(1000)

    conn
    |> put_status(:not_found)
    |> json(%{error: "Game not found"})
  end

  defp handle_error(conn, message) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: message})
  end
end
