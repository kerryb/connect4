defmodule Connect4.Game do
  @moduledoc """
  A GenServer holding the state of a single game.
  """
  use GenServer

  @enforce_keys [:next_player, :grid]
  defstruct [:next_player, :grid]

  @type player :: :O | :X
  @type column :: 0..6
  @type row :: 0..5
  @type grid :: %{column() => %{row() => player()}}
  @type t :: %__MODULE__{next_player: player(), grid: grid()}

  defimpl Inspect do
    def inspect(game, _opts), do: rows(game.grid) <> "\n(#{game.next_player} to play)"

    defp rows(grid), do: 5..0 |> Enum.map_join("\n", &row(grid, &1))

    defp row(grid, row), do: 0..6 |> Enum.map_join(" ", &cell(grid, row, &1))

    defp cell(grid, row, column), do: grid |> Map.get(column, %{}) |> Map.get(row, ".")
  end

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(_arg) do
    GenServer.start_link(__MODULE__, nil)
  end

  @spec new :: t()
  def new do
    %__MODULE__{next_player: :O, grid: %{}}
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

  def handle_call({:play, player, column}, _from, %{next_player: player} = game) do
    grid = place(game.grid, player, column)
    next_player = other_player(player)
    game = %{game | next_player: next_player, grid: grid}
    {:reply, {:ok, game}, game}
  end

  def handle_call({:play, _player, _column}, _from, game) do
    {:reply, {:error, "Not your turn"}, game}
  end

  defp place(grid, player, column) do
    Map.update(grid, column, %{0 => player}, &place_in_column(&1, player))
  end

  defp place_in_column(column, player), do: Map.put(column, next_free_row(column), player)

  defp next_free_row(column), do: (column |> Map.keys() |> Enum.max(&>=/2, fn -> 0 end)) + 1

  defp other_player(:O), do: :X
  defp other_player(:X), do: :O
end
