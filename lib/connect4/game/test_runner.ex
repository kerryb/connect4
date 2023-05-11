defmodule Connect4.Game.TestRunner do
  @moduledoc """
  A server to handle running of test games.

  Test games are not inserted in the database, and do not affect scoring.
  """

  use GenServer

  alias Connect4.Game.Game

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec play(String.t(), integer()) :: {:ok, Game.t()} | {:error, any()}
  def play(player_code, column) do
    GenServer.call(__MODULE__, {:play, player_code, column})
  end

  @spec find_or_start_game(String.t()) :: {:ok, Game.t()} | {:error, String.t()}
  def find_or_start_game(player_code) do
    GenServer.call(__MODULE__, {:find_or_start_game, player_code})
  end

  @impl GenServer
  def init(_opts) do
    {:ok, %{games: %{}}}
  end

  @impl GenServer
  def handle_call({:play, player_code, column}, _from, state) do
    {id, state} =
      case state.games[player_code] do
        nil ->
          id = start_game(player_code)
          {id, register_game(state, player_code, id)}

        id ->
          {id, state}
      end

    case Game.play(id, :test, column) do
      {:ok, game} -> {:reply, {:ok, game}, state}
      error -> {:reply, error, state}
    end
  end

  def handle_call({:find_or_start_game, player_code}, _from, state) do
    id =
      case state.games[player_code] do
        nil ->
          id = start_game(player_code)
          register_game(state, player_code, id)
          id

        id ->
          id
      end

    {:reply, {:ok, Game.get(id)}, state}
  end

  defp start_game(player_code) do
    id = "test-#{player_code}"
    {:ok, _pid} = Game.start_link(id: id)
    id
  end

  defp register_game(state, player_code, game_id) do
    Map.update!(state, :games, fn games ->
      Map.put(games, player_code, game_id)
    end)
  end
end
