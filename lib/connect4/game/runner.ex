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
  alias Phoenix.PubSub

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @spec start_game(String.t(), String.t(), integer(), GenServer.server()) ::
          {:ok, integer()} | {:error, any()}
  def start_game(player_o_code, player_x_code, timeout, pid \\ __MODULE__) do
    GenServer.call(pid, {:start_game, player_o_code, player_x_code, timeout})
  end

  @spec play(String.t(), integer(), GenServer.server()) :: {:ok, Game.board()} | {:error, any()}
  def play(player_code, column, pid \\ __MODULE__) do
    GenServer.call(pid, {:play, player_code, column})
  end

  @impl GenServer
  def init(_opts) do
    PubSub.subscribe(Connect4.PubSub, "games")
    {:ok, %{games: %{}}}
  end

  @impl GenServer
  def handle_call({:start_game, player_o_code, player_x_code, timeout}, _from, state) do
    with {:ok, game} <- GameQueries.insert_from_codes(player_o_code, player_x_code),
         {:ok, _pid} <- Game.start_link(id: game.id, timeout: timeout) do
      {:reply, {:ok, game.id}, register_game(state, player_o_code, player_x_code, game.id)}
    else
      error -> {:reply, error, state}
    end
  end

  def handle_call({:play, player_code, column}, _from, state) do
    with {id, player} <- state.games[player_code],
         {:ok, game} <- Game.play(id, player, column) do
      {:reply, {:ok, game.board}, state}
    else
      nil -> {:reply, {:error, "Game not found"}}
      error -> {:reply, error}
    end
  end

  @impl GenServer
  def handle_info({:completed, id, winner, _board}, state) do
    GameQueries.update_winner(id, winner)
    PubSub.broadcast(Connect4.PubSub, "tournament", :game_finished)
    {:noreply, state}
  end

  defp register_game(state, player_o_code, player_x_code, game_id) do
    Map.update!(state, :games, fn games ->
      games
      |> Map.put(player_o_code, {game_id, :O})
      |> Map.put(player_x_code, {game_id, :X})
    end)
  end
end
