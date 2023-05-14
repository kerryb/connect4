defmodule Connect4.Game.Scheduler do
  @moduledoc """
  A GenServer to start games at regular intervals.
  """
  use GenServer

  alias Connect4.Auth.Queries.PlayerQueries
  alias Connect4.Game.Runner
  alias Phoenix.PubSub

  defstruct active?: false, interval_minutes: 5, tick_timer_ref: nil, round_timer_ref: nil

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec active? :: boolean()
  def active?, do: GenServer.call(__MODULE__, :active?)

  @spec activate(integer()) :: :ok
  def activate(interval_minutes), do: GenServer.cast(__MODULE__, {:activate, interval_minutes})

  @spec deactivate :: :ok
  def deactivate, do: GenServer.cast(__MODULE__, :deactivate)

  @spec interval_minutes :: integer()
  def interval_minutes, do: GenServer.call(__MODULE__, :interval_minutes)

  @spec seconds_to_go(NaiveDateTime.t()) :: integer()
  def seconds_to_go(now \\ NaiveDateTime.utc_now()), do: GenServer.call(__MODULE__, {:seconds_to_go, now})

  @impl GenServer
  def init(_opts), do: {:ok, %__MODULE__{}}

  @impl GenServer
  def handle_call(:active?, _from, state), do: {:reply, state.active?, state}
  def handle_call(:interval_minutes, _from, state), do: {:reply, state.interval_minutes, state}

  def handle_call({:seconds_to_go, _now}, _from, %{active?: false} = state), do: {:reply, nil, state}

  def handle_call({:seconds_to_go, now}, _from, state) do
    {:reply, calculate_seconds_to_go(state.interval_minutes, now), state}
  end

  @impl GenServer
  def handle_cast({:activate, interval_minutes}, state) do
    tick_timer_ref = Process.send_after(self(), :tick, 1000)
    seconds_to_go = calculate_seconds_to_go(interval_minutes)
    round_timer_ref = Process.send_after(self(), :start_round, :timer.seconds(seconds_to_go))

    {:noreply,
     %{
       state
       | active?: true,
         interval_minutes: interval_minutes,
         tick_timer_ref: tick_timer_ref,
         round_timer_ref: round_timer_ref
     }}
  end

  def handle_cast(:deactivate, state) do
    if state.tick_timer_ref, do: Process.cancel_timer(state.tick_timer_ref)
    if state.round_timer_ref, do: Process.cancel_timer(state.round_timer_ref)
    PubSub.broadcast!(Connect4.PubSub, "scheduler", :deactivated)
    {:noreply, %{state | active?: false, tick_timer_ref: nil}}
  end

  @impl GenServer
  def handle_info(:tick, state) do
    tick_timer_ref = Process.send_after(self(), :tick, 1000)

    PubSub.broadcast!(
      Connect4.PubSub,
      "scheduler",
      {:seconds_to_go, calculate_seconds_to_go(state.interval_minutes)}
    )

    {:noreply, %{state | tick_timer_ref: tick_timer_ref}}
  end

  def handle_info(:start_round, state) do
    seconds_to_go = calculate_seconds_to_go(state.interval_minutes)
    round_timer_ref = Process.send_after(self(), :start_round, :timer.seconds(seconds_to_go))

    PlayerQueries.active()
    |> Enum.shuffle()
    |> Enum.chunk_every(2, 2, [%{code: "bot-simple"}])
    |> Enum.each(fn [player_1, player_2] ->
      Runner.start_game(player_1.code, player_2.code, :timer.seconds(1), :timer.seconds(30))
    end)

    PubSub.broadcast!(Connect4.PubSub, "scheduler", :round_started)
    {:noreply, %{state | round_timer_ref: round_timer_ref}}
  end

  def handle_info(_message, state), do: {:noreply, state}

  defp calculate_seconds_to_go(interval_minutes, now \\ NaiveDateTime.utc_now()) do
    with {:ok, crontab} <- Crontab.CronExpression.Parser.parse("*/#{interval_minutes}"),
         {:ok, next_game_at} <- Crontab.Scheduler.get_next_run_date(crontab, now) do
      NaiveDateTime.diff(next_game_at, now)
    end
  end
end
