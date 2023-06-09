# credo:disable-for-this-file Credo.Check.Refactor.ModuleDependencies
defmodule Connect4.Game.Game do
  @moduledoc """
  A GenServer holding the state of a single game.
  """
  use GenServer

  alias Connect4.GameRegistry
  alias Phoenix.PubSub

  @enforce_keys [:id]
  defstruct id: nil,
            board: %{},
            next_player: :O,
            winner: nil,
            timed_out?: false,
            timeout: nil,
            first_move_timeout: nil,
            timer_ref: nil,
            played: MapSet.new()

  @type column :: 0..6
  @type row :: 0..5
  @type board :: %{column() => %{row() => player()}}
  @type player :: :O | :X
  @type t :: %__MODULE__{
          id: GenServer.server(),
          board: board(),
          next_player: player(),
          played: MapSet.t(player()),
          winner: player() | :tie | nil,
          timed_out?: boolean(),
          timeout: integer(),
          first_move_timeout: integer(),
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
    GenServer.start_link(__MODULE__, opts, name: {:via, Registry, {GameRegistry, opts[:id]}})
  end

  @spec get(any()) :: t()
  def get(id) do
    case Registry.lookup(GameRegistry, id) do
      [{pid, _name}] -> GenServer.call(pid, :get)
      _missing -> {:error, :not_found}
    end
  end

  @spec play(GenServer.server(), player() | :test, column()) :: any()
  def play(id, player, column) do
    case Registry.lookup(GameRegistry, id) do
      [{pid, _name}] -> GenServer.call(pid, {:play, player, column})
      _missing -> {:error, :not_found}
    end
  end

  @spec terminate(GenServer.server()) :: :ok
  def terminate(id) do
    with [{pid, _name}] <- Registry.lookup(GameRegistry, id),
         true <- Process.alive?(pid) do
      GenServer.call(pid, :terminate)
      :ok
    else
      _not_found -> :ok
    end
  end

  @impl GenServer
  def init(opts) do
    game = %__MODULE__{id: opts[:id]}
    timer_ref = start_timer(opts[:first_move_timeout], game.timer_ref)
    {:ok, %{game | timeout: opts[:timeout], first_move_timeout: opts[:first_move_timeout], timer_ref: timer_ref}}
  end

  @impl GenServer
  def handle_call(:get, _from, game), do: {:reply, game, game}

  def handle_call({:play, player, column_str}, _from, game) do
    play_as = if player == :test, do: game.next_player, else: player
    column = parse_column(column_str)

    cond do
      play_as != game.next_player ->
        {:reply, {:error, "Not your turn"}, mark_played(game, play_as)}

      column not in 0..6 ->
        {:reply, {:error, "Column must be 0..6"}, mark_played(game, play_as)}

      game.board
      |> Map.get(column, %{})
      |> filled_row() == 5 ->
        {:reply, {:error, "Column is full"}, mark_played(game, play_as)}

      true ->
        play_move(game, play_as, column)
    end
  end

  def handle_call(:terminate, _from, game) do
    complete_game(game, :tie)
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
      true -> complete_move(game, player)
    end
  end

  defp complete_game(game, winner) do
    stop_timer(game.timer_ref)
    game = %{game | next_player: nil, winner: winner, timed_out?: false, timer_ref: nil}
    broadcast_completion(game)
    {:stop, :normal, {:ok, game}, game}
  end

  defp complete_move(game, player) do
    next_player = other_player(game.next_player)
    timeout = timeout_for_move(game, next_player)
    timer_ref = start_timer(timeout, game.timer_ref)

    game =
      mark_played(
        %{game | next_player: next_player, timed_out?: false, timer_ref: timer_ref},
        player
      )

    broadcast_move(game)
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
    timeout = timeout_for_move(game, next_player)
    timer_ref = start_timer(timeout, game.timer_ref)

    {:noreply, %{game | next_player: next_player, timed_out?: true, timer_ref: timer_ref}}
  end

  defp timeout_for_move(game, next_player) do
    if MapSet.member?(game.played, next_player) do
      game.timeout
    else
      game.first_move_timeout
    end
  end

  defp start_timer(nil, _old_timer_ref), do: nil

  defp start_timer(timeout, old_timer_ref) do
    stop_timer(old_timer_ref)
    Process.send_after(self(), :timeout, timeout)
  end

  defp stop_timer(nil), do: :ok
  defp stop_timer(ref), do: Process.cancel_timer(ref)

  defp broadcast_move(game) do
    PubSub.broadcast!(Connect4.PubSub, "games", {:move, game})
  end

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

  defp mark_played(game, player) do
    Map.update!(game, :played, &MapSet.put(&1, player))
  end
end
