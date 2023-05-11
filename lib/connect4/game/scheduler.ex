defmodule Connect4.Game.Scheduler do
  @moduledoc """
  A GenServer to start games at regular intervals.
  """
  use GenServer

  alias Phoenix.PubSub

  @enforce_keys [:active?, :interval_minutes]
  defstruct [:active?, :interval_minutes, :timer_ref]

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec active? :: boolean()
  def active?, do: GenServer.call(__MODULE__, :active?)

  @spec activate :: :ok
  def activate, do: GenServer.cast(__MODULE__, :activate)

  @spec deactivate :: :ok
  def deactivate, do: GenServer.cast(__MODULE__, :deactivate)

  @spec interval_minutes :: integer()
  def interval_minutes, do: GenServer.call(__MODULE__, :interval_minutes)

  @spec seconds_to_go(NaiveDateTime.t()) :: integer()
  def seconds_to_go(now \\ NaiveDateTime.utc_now()), do: GenServer.call(__MODULE__, {:seconds_to_go, now})

  @impl GenServer
  def init(_opts) do
    {:ok, %__MODULE__{active?: false, interval_minutes: 10}}
  end

  @impl GenServer
  def handle_call(:active?, _from, state), do: {:reply, state.active?, state}
  def handle_call(:interval_minutes, _from, state), do: {:reply, state.interval_minutes, state}

  def handle_call({:seconds_to_go, _now}, _from, %{active?: false} = state), do: {:reply, nil, state}

  def handle_call({:seconds_to_go, now}, _from, state) do
    {:reply, calculate_seconds_to_go(state.interval_minutes, now), state}
  end

  @impl GenServer
  def handle_cast(:activate, state) do
    timer_ref = Process.send_after(self(), :broadcast_seconds_remaining, 1000)
    {:noreply, %{state | active?: true, timer_ref: timer_ref}}
  end

  def handle_cast(:deactivate, state) do
    if state.timer_ref, do: Process.cancel_timer(state.timer_ref)
    PubSub.broadcast!(Connect4.PubSub, "scheduler", :deactivated)
    {:noreply, %{state | active?: false, timer_ref: nil}}
  end

  @impl GenServer
  def handle_info(:broadcast_seconds_remaining, state) do
    timer_ref = Process.send_after(self(), :broadcast_seconds_remaining, 1000)

    PubSub.broadcast!(
      Connect4.PubSub,
      "scheduler",
      {:seconds_to_go, calculate_seconds_to_go(state.interval_minutes)}
    )

    {:noreply, %{state | timer_ref: timer_ref}}
  end

  defp calculate_seconds_to_go(interval_minutes, now \\ NaiveDateTime.utc_now()) do
    with {:ok, crontab} <- Crontab.CronExpression.Parser.parse("*/#{interval_minutes}"),
         {:ok, next_game_at} <- Crontab.Scheduler.get_next_run_date(crontab, now) do
      NaiveDateTime.diff(next_game_at, now)
    end
  end
end
