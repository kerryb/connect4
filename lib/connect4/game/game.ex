defmodule Connect4.Game do
  @moduledoc """
  A GenServer holding the state of a single game.
  """
  use GenServer

  alias Connect4.GameRegistry

  @enforce_keys [:board, :next_player]
  defstruct [:board, :next_player, :winner]

  @type column :: 0..6
  @type row :: 0..5
  @type board :: %{column() => %{row() => player()}}
  @type player :: :O | :X
  @type t :: %__MODULE__{board: board(), next_player: player(), winner: player() | :tie | nil}

  defimpl Inspect do
    def inspect(game, _opts), do: rows(game.board) <> "\n(#{state(game)})"

    defp rows(board), do: 5..0 |> Enum.map_join("\n", &row(board, &1))

    defp row(board, row), do: 0..6 |> Enum.map_join(" ", &cell(board, row, &1))

    defp cell(board, row, column), do: board |> Map.get(column, %{}) |> Map.get(row, ".")

    defp state(%{winner: nil} = game), do: "#{game.next_player} to play"
    defp state(%{winner: winner}), do: "#{winner} has won"
  end

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(id) do
    GenServer.start_link(__MODULE__, nil, name: via_tuple(id))
  end

  @spec next_player(any()) :: player()
  def next_player(id), do: id |> via_tuple() |> GenServer.call(:next_player)

  @spec play(GenServer.server(), player(), column()) :: any()
  def play(id, player, column), do: id |> via_tuple() |> GenServer.call({:play, player, column})

  defp via_tuple(id), do: {:via, Registry, {GameRegistry, id}}

  @impl GenServer
  def init(_arg) do
    {:ok, %__MODULE__{next_player: :O, board: %{}}}
  end

  @impl GenServer
  def handle_call(:next_player, _from, game), do: {:reply, game.next_player, game}

  def handle_call({:play, player, column}, _from, game) do
    cond do
      player != game.next_player ->
        {:reply, {:error, "Not your turn"}, game}

      column not in 0..6 ->
        {:reply, {:error, "Column must be 0..6"}, game}

      game.board |> Map.get(column, %{}) |> filled_row() == 5 ->
        {:reply, {:error, "Column is full"}, game}

      true ->
        board = place(game.board, player, column)

        {next_player, winner} =
          cond do
            tied?(board) ->
              {nil, :tie}

            won?(board, player, column) ->
              {nil, player}

            true ->
              {other_player(player), nil}
          end

        game = %{game | board: board, next_player: next_player, winner: winner}
        {:reply, {:ok, game}, game}
    end
  end

  defp place(board, player, column) do
    Map.update(board, column, %{0 => player}, &place_in_column(&1, player))
  end

  defp place_in_column(column, player), do: Map.put(column, filled_row(column) + 1, player)

  defp filled_row(column), do: length(Map.keys(column)) - 1

  defp tied?(board), do: Enum.all?(0..6, &column_full?(board, &1))

  defp column_full?(board, column_no), do: board |> Map.get(column_no, %{}) |> filled_row() == 5

  defp won?(board, player, column) do
    completed_row?(board, player, column) or
      completed_column?(board, player, column) or
      completed_left_diagonal?(board, player, column) or
      completed_right_diagonal?(board, player, column)
  end

  defp completed_row?(board, player, column) do
    row_index = filled_row(board[column])

    owned_cells =
      board
      |> Enum.filter(fn {_, column} -> player == column[row_index] end)
      |> Enum.map(&elem(&1, 0))

    Enum.any?(0..3, fn start -> Enum.all?(start..(start + 3), &(&1 in owned_cells)) end)
  end

  defp completed_column?(board, player, column) do
    row_index = filled_row(board[column])
    Enum.all?(row_index..(row_index - 3), &(board[column][&1] == player))
  end

  defp completed_left_diagonal?(board, player, column) do
    completed_diagonal?(board, player, column, &Kernel.+/2)
  end

  defp completed_right_diagonal?(board, player, column) do
    completed_diagonal?(board, player, column, &Kernel.-/2)
  end

  defp completed_diagonal?(board, player, column, offset_column) do
    row_index = filled_row(board[column])
    Enum.all?(0..3, &(Map.get(board, offset_column.(column, &1), %{})[row_index - &1] == player))
  end

  defp other_player(:O), do: :X
  defp other_player(:X), do: :O
end
