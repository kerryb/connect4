defmodule Connect4Web.GameController do
  use Connect4Web, :controller

  alias Connect4.Game.Runner
  alias Connect4Web.GameJSON

  def show(conn, %{"code" => code}) do
    case Runner.find_game(code) do
      {:ok, player, game} ->
        Runner.find_game(code)
        json(conn, GameJSON.render(game, player))

      {:error, message} ->
        conn |> put_status(:not_found) |> json(%{error: message})
    end
  end

  def play(conn, %{"code" => code, "column" => column}) when column in ~w[0 1 2 3 4 5 6] do
    case Runner.play(code, String.to_integer(column)) do
      {:ok, player, game} ->
        json(conn, GameJSON.render(game, player))

      {:error, message} ->
        conn |> put_status(:bad_request) |> json(%{error: message})
    end
  end
end
