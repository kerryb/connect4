defmodule Connect4.Game.Runner do
  @moduledoc """
  A server to handle running of games.

  When a game is started, a record is created in the database, and the row ID
  is then used as the identifier when starting a `Connect4.Game.Game` server.

  When the game completes, the database record is updated.

  During the game, the runner holds a reference to it in memory, rather than
  querying the database for every move.
  """

  use GenServer

  alias Connect4.Game.Game
  alias Connect4.Game.Queries.GameQueries

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @spec start_game(String.t(), String.t()) :: {:ok, integer()} | {:error, any()}
  def start_game(player_o_code, player_x_code) do
    with {:ok, game} <- GameQueries.insert_from_codes(player_o_code, player_x_code),
         {:ok, _pid} <- Game.start_link(id: game.id) do
      {:ok, game.id}
    else
      error -> error
    end
  end

  @impl GenServer
  def init(_opts) do
    {:ok, nil}
  end
end
