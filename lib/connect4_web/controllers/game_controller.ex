# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Connect4Web.GameController do
  use Connect4Web, :controller

  alias Connect4.Game.Runner
  alias Connect4Web.GameJSON
  alias Phoenix.PubSub

  def show(conn, %{"code" => code}) do
    case Runner.find_game(code) do
      {:ok, player, game} -> json(conn, GameJSON.render(game, player))
      {:error, _message} -> not_found(conn)
    end
  end

  def play(conn, %{"code" => code, "column" => column}) do
    :ok = PubSub.subscribe(Connect4.PubSub, "games")

    case Runner.play(code, column) do
      {:ok, player, game} -> successfule_move(conn, player, game)
      {:error, :not_found} -> not_found(conn)
      {:error, message} -> handle_error(conn, message)
    end
  end

  defp successfule_move(conn, player, game) do
    json(conn, GameJSON.render(game, player))
  end

  defp not_found(conn), do: handle_error(conn, "Game not found", 404)

  defp handle_error(conn, message, status \\ :bad_request) do
    Process.sleep(500)

    conn
    |> put_status(status)
    |> json(%{error: message})
  end
end
