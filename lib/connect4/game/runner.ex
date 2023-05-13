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
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec start_game(String.t(), String.t(), integer(), integer()) ::
          {:ok, integer()} | {:error, any()}
  def start_game(player_o_code, player_x_code, timeout, first_move_timeout) do
    GenServer.call(
      __MODULE__,
      {:start_game, player_o_code, player_x_code, timeout, first_move_timeout}
    )
  end

  @spec play(String.t(), String.t()) :: {:ok, Game.player(), Game.t()} | {:error, any()}
  def play(player_code, column) do
    GenServer.call(__MODULE__, {:play, player_code, column})
  end

  @spec find_game(String.t()) ::
          {:ok, Game.player(), Game.t()} | {:error, String.t()}
  def find_game(player_code) do
    GenServer.call(__MODULE__, {:find_game, player_code})
  end

  @impl GenServer
  def init(_opts) do
    PubSub.subscribe(Connect4.PubSub, "games")
    {:ok, %{games: %{}}}
  end

  @impl GenServer
  def handle_call({:start_game, player_o_code, player_x_code, timeout, first_move_timeout}, _from, state) do
    with {:ok, game} <- GameQueries.insert_from_codes(player_o_code, player_x_code),
         {:ok, _pid} <-
           Game.start_link(id: game.id, timeout: timeout, first_move_timeout: first_move_timeout) do
      {:reply, {:ok, game.id}, register_game(state, player_o_code, player_x_code, game.id)}
    else
      error -> {:reply, error, state}
    end
  end

  def handle_call({:play, player_code, column}, _from, state) do
    with {id, player} <- state.games[player_code],
         {:ok, game} <- Game.play(id, player, column) do
      {:reply, {:ok, player, game}, state}
    else
      nil -> {:reply, {:error, :not_found}, state}
      error -> {:reply, error, state}
    end
  end

  def handle_call({:find_game, player_code}, _from, state) do
    with {id, player} <- state.games[player_code],
         game <- Game.get(id) do
      {:reply, {:ok, player, game}, state}
    else
      _error -> {:reply, {:error, :not_found}, state}
    end
  end

  @impl GenServer
  def handle_info({:completed, game}, state) do
    case GameQueries.update_winner(game.id, game.winner, game.board) do
      {:ok, game} -> PubSub.broadcast!(Connect4.PubSub, "runner", {:game_finished, game})
      _error -> :ignore
    end

    {:noreply, state}
  end

  defp register_game(state, player_o_code, player_x_code, game_id) do
    complete_existing_game(state.games[player_o_code])
    complete_existing_game(state.games[player_x_code])

    Map.update!(state, :games, fn games ->
      games
      |> Map.put(player_o_code, {game_id, :O})
      |> Map.put(player_x_code, {game_id, :X})
    end)
  end

  defp complete_existing_game(nil), do: :ok
  defp complete_existing_game({id, _player}), do: Game.terminate(id)
end
