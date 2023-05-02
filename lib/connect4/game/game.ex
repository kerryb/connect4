defmodule Connect4.Game do
  use GenServer

  @enforce_keys [:state]
  defstruct [:state]

  @type state :: :player_1_to_play
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

  @impl GenServer
  def init(_arg) do
    {:ok, new()}
  end

  @impl GenServer
  def handle_call(:state, _from, game), do: {:reply, game.state, game}
end
