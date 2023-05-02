defmodule Connect4.Game do
  @moduledoc """
  A GenServer holding the state of a single game.
  """
  use GenServer

  @enforce_keys [:next_player]
  defstruct [:next_player]

  @type player :: :O | :X
  @type column :: 0..6
  @type t :: %__MODULE__{next_player: player()}

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(_arg) do
    GenServer.start_link(__MODULE__, nil)
  end

  @spec new :: t()
  def new do
    %__MODULE__{next_player: :O}
  end

  @spec next_player(GenServer.server()) :: player()
  def next_player(game), do: GenServer.call(game, :next_player)

  @spec play(GenServer.server(), player(), column()) :: any()
  def play(game, player, column), do: GenServer.call(game, {:play, player, column})

  @impl GenServer
  def init(_arg) do
    {:ok, new()}
  end

  @impl GenServer
  def handle_call(:next_player, _from, game), do: {:reply, game.next_player, game}

  def handle_call({:play, player, _column}, _from, %{next_player: player} = game) do
    next_player = if player == :O, do: :X, else: :O
    game = %{game | next_player: next_player}
    {:reply, {:ok, game}, game}
  end

  def handle_call({:play, _player, _column}, _from, game) do
    {:reply, {:error, "Not your turn"}, game}
  end
end
