defmodule Connect4.Game.Scheduler do
  @moduledoc """
  A GenServer to start games at regular intervals.
  """
  use GenServer

  @enforce_keys [:active?, :interval_minutes]
  defstruct [:active?, :interval_minutes]

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
    with {:ok, crontab} <- Crontab.CronExpression.Parser.parse("*/#{state.interval_minutes}"),
         {:ok, next_game_at} <- Crontab.Scheduler.get_next_run_date(crontab, now),
         seconds_to_go <- NaiveDateTime.diff(next_game_at, now) do
      {:reply, seconds_to_go, state}
    end
  end

  @impl GenServer
  def handle_cast(:activate, state), do: {:noreply, %{state | active?: true}}
  def handle_cast(:deactivate, state), do: {:noreply, %{state | active?: false}}
end
