defmodule Connect4.Game do
  @moduledoc """
  A GenServer holding the state of a single game.
  """
  use GenServer

  @enforce_keys [:board, :next_player]
  defstruct [:board, :next_player, :winner]

  @type column :: 0..6
  @type row :: 0..5
  @type board :: %{column() => %{row() => player()}}
  @type player :: :O | :X
  @type t :: %__MODULE__{board: board(), next_player: player(), winner: player() | nil}

  defimpl Inspect do
    def inspect(game, _opts), do: rows(game.board) <> "\n(#{game.next_player} to play)"

    defp rows(board), do: 5..0 |> Enum.map_join("\n", &row(board, &1))

    defp row(board, row), do: 0..6 |> Enum.map_join(" ", &cell(board, row, &1))

    defp cell(board, row, column), do: board |> Map.get(column, %{}) |> Map.get(row, ".")
  end

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(_arg) do
    GenServer.start_link(__MODULE__, nil)
  end

  @spec new :: t()
  def new do
    %__MODULE__{next_player: :O, board: %{}}
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
    board = place(game.board, player, column)

    {next_player, winner} =
      if won?(board, player, column) do
        {nil, player}
      else
        {other_player(player), nil}
      end

    game = %{game | board: board, next_player: next_player, winner: winner}
    {:reply, {:ok, game}, game}
  end

  def handle_call({:play, _player, _column}, _from, game) do
    {:reply, {:error, "Not your turn"}, game}
  end

  defp place(board, player, column) do
    Map.update(board, column, %{0 => player}, &place_in_column(&1, player))
  end

  defp place_in_column(column, player), do: Map.put(column, filled_row(column) + 1, player)

  defp filled_row(column), do: length(Map.keys(column)) - 1

  defp won?(board, player, column) do
    row_index = filled_row(board[column])

    owned_cells =
      board
      |> Enum.filter(fn {_, column} -> player == column[row_index] end)
      |> Enum.map(&elem(&1, 0))

    Enum.any?(0..3, fn start -> Enum.all?(start..(start + 3), &(&1 in owned_cells)) end)
  end

  defp other_player(:O), do: :X
  defp other_player(:X), do: :O
end
