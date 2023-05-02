defmodule Connect4.Game do
  use GenServer

  defstruct [:state]

  def start_link(_arg) do
    GenServer.start_link(__MODULE__, nil)
  end

  def new do
    %__MODULE__{state: :player_1_to_play}
  end

  def state(game), do: GenServer.call(game, :state)

  @impl GenServer
  def init(_arg) do
    {:ok, new()}
  end

  @impl GenServer
  def handle_call(:state, _from, game), do: {:reply, game.state, game}
end
