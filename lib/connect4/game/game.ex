# credo:disable-for-this-file Credo.Check.Refactor.ModuleDependencies
defmodule Connect4.Game.Game do
  @moduledoc """
  A GenServer holding the state of a single game.
  """
  use GenServer

  alias Connect4.GameRegistry
  alias Phoenix.PubSub

  @enforce_keys [:id, :board, :next_player]
  defstruct [:id, :board, :next_player, :winner, :timed_out?, :timeout, :timer_ref]

  @type column :: 0..6
  @type row :: 0..5
  @type board :: %{column() => %{row() => player()}}
  @type player :: :O | :X
  @type t :: %__MODULE__{
          id: GenServer.server(),
          board: board(),
          next_player: player(),
          winner: player() | :tie | nil,
          timed_out?: boolean(),
          timeout: integer(),
          timer_ref: reference() | nil
        }

  defimpl Inspect do
    @spec inspect(Connect4.Game.Game.t(), Inspect.Opts.t()) :: String.t()
    def inspect(game, _opts) do
      board = rows(game.board)
      state = state(game)
      "#{board}\n(#{state})"
    end

    defp rows(board), do: Enum.map_join(5..0, "\n", &row(board, &1))

    defp row(board, row), do: Enum.map_join(0..6, " ", &cell(board, row, &1))

    defp cell(board, row, column) do
      board
      |> Map.get(column, %{})
      |> Map.get(row, ".")
    end

    defp state(%{winner: nil} = game), do: "#{game.next_player} to play"
    defp state(%{winner: winner}), do: "#{winner} has won"
  end

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: via_tuple(opts[:id]))
  end

  @spec get(any()) :: t()
  def get(id) do
    id
    |> via_tuple()
    |> GenServer.call(:get)
  end

  @spec play(GenServer.server(), player(), column()) :: any()
  def play(id, player, column) do
    id
    |> via_tuple()
    |> GenServer.call({:play, player, column})
  end

  defp via_tuple(id), do: {:via, Registry, {GameRegistry, id}}

  @impl GenServer
  def init(opts) do
    game = %__MODULE__{id: opts[:id], next_player: :O, board: %{}, timed_out?: false}
    timer_ref = start_timer(opts[:timeout], nil)
    {:ok, %{game | timeout: opts[:timeout], timer_ref: timer_ref}}
  end

  @impl GenServer
  def handle_call(:get, _from, game), do: {:reply, game, game}

  def handle_call({:play, player, column_str}, _from, game) do
    column = parse_column(column_str)

    cond do
      player != game.next_player ->
        {:reply, {:error, "Not your turn"}, game}

      column not in 0..6 ->
        {:reply, {:error, "Column must be 0..6"}, game}

      game.board
      |> Map.get(column, %{})
      |> filled_row() == 5 ->
        {:reply, {:error, "Column is full"}, game}

      true ->
        play_move(game, player, column)
    end
  end

  defp parse_column(column_str) do
    case Integer.parse(column_str) do
      {col, ""} -> col
      _error -> ""
    end
  end

  defp play_move(game, player, column) do
    game = Map.update!(game, :board, &place(&1, player, column))

    cond do
      tied?(game.board) -> complete_game(game, :tie)
      won?(game.board, player, column) -> complete_game(game, player)
      true -> complete_move(game)
    end
  end

  defp complete_game(game, winner) do
    stop_timer(game.timer_ref)
    game = %{game | next_player: nil, winner: winner, timed_out?: false, timer_ref: nil}
    broadcast_completion(game)
    {:stop, :normal, {:ok, game}, game}
  end

  defp complete_move(game) do
    game = %{
      game
      | next_player: other_player(game.next_player),
        timed_out?: false,
        timer_ref: start_timer(game.timeout, game.timer_ref)
    }

    {:reply, {:ok, game}, game}
  end

  @impl GenServer
  def handle_info(:timeout, %{timed_out?: true} = game) do
    game = %{game | next_player: nil, winner: :tie}
    broadcast_completion(game)
    {:noreply, game}
  end

  def handle_info(:timeout, game) do
    next_player = other_player(game.next_player)
    start_timer(game.timeout, game.timer_ref)
    {:noreply, %{game | next_player: next_player, timed_out?: true}}
  end

  defp start_timer(nil, _old_timer_ref), do: nil

  defp start_timer(timeout, old_timer_ref) do
    stop_timer(old_timer_ref)
    Process.send_after(self(), :timeout, timeout)
  end

  defp stop_timer(nil), do: :ok
  defp stop_timer(ref), do: Process.cancel_timer(ref)

  defp broadcast_completion(game) do
    PubSub.broadcast!(Connect4.PubSub, "games", {:completed, game})
  end

  defp place(board, player, column) do
    Map.update(board, column, %{0 => player}, &place_in_column(&1, player))
  end

  defp place_in_column(column, player), do: Map.put(column, filled_row(column) + 1, player)

  defp filled_row(column), do: length(Map.keys(column)) - 1

  defp tied?(board), do: Enum.all?(0..6, &column_full?(board, &1))

  defp column_full?(board, column_no) do
    board
    |> Map.get(column_no, %{})
    |> filled_row() == 5
  end

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
      |> Enum.filter(fn {_index, column} -> player == column[row_index] end)
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
