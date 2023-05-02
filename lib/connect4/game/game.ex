defmodule Connect4.Game do
  @moduledoc """
  A GenServer holding the state of a single game.
  """
  use GenServer

  @enforce_keys [:state]
  defstruct [:state]

  @type state :: :player_1_to_play
  @type player :: :player_1 | :player_2
  @type column :: 0..6
  @type t :: %__MODULE__{state: state()}

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(_arg) do
    GenServer.start_link(__MODULE__, nil)
  end

  @spec new :: t()
  def new do
    %__MODULE__{state: :player_1_to_play}
  end

  @spec state(GenServer.server()) :: state()
  def state(game), do: GenServer.call(game, :state)

  @spec play(GenServer.server(), player(), column()) :: any()
  def play(game, player, column), do: GenServer.cast(game, {:play, player, column})

  @impl GenServer
  def init(_arg) do
    {:ok, new()}
  end

  @impl GenServer
  def handle_call(:state, _from, game), do: {:reply, game.state, game}

  @impl GenServer
  def handle_cast({:play, _player, _column}, game) do
    game = %{game | state: :player_2_to_play}
    {:noreply, game}
  end
end
