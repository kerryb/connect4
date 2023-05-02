defmodule Connect4.Game do
  @moduledoc """
  A GenServer holding the state of a single game.
  """
  use GenServer

  @enforce_keys [:next_player]
  defstruct [:next_player]

  @type player :: :player_1 | :player_2
  @type column :: 0..6
  @type t :: %__MODULE__{next_player: player()}

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(_arg) do
    GenServer.start_link(__MODULE__, nil)
  end

  @spec new :: t()
  def new do
    %__MODULE__{next_player: :player_1}
  end

  @spec next_player(GenServer.server()) :: player()
  def next_player(game), do: GenServer.call(game, :next_player)

  @spec play(GenServer.server(), player(), column()) :: any()
  def play(game, player, column), do: GenServer.cast(game, {:play, player, column})

  @impl GenServer
  def init(_arg) do
    {:ok, new()}
  end

  @impl GenServer
  def handle_call(:next_player, _from, game), do: {:reply, game.next_player, game}

  @impl GenServer
  def handle_cast({:play, player, _column}, game) do
    next_player = if player == :player_1, do: :player_2, else: :player_1
    game = %{game | next_player: next_player}
    {:noreply, game}
  end
end
