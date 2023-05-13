defmodule Connect4.Bot.Simple do
  @moduledoc """
  A simple bot to make up the numbers if there’s an odd number of players.
  """

  use GenServer

  alias Connect4.Auth.Queries.PlayerQueries
  alias Connect4.Auth.Schema.Player
  alias Connect4.Game.Runner
  alias Connect4.Repo

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl GenServer
  def init(_arg) do
    send(self(), :play)

    unless PlayerQueries.from_code("bot-simple") do
      Repo.insert!(%Player{
        email: "simple-bot@example.com",
        name: "Simple Bot",
        code: "bot-simple",
        hashed_password: "invalid"
      })
    end

    {:ok, %{column: 0}}
  end

  @impl GenServer
  def handle_info(:play, %{column: column}) do
    Runner.play("bot-simple", to_string(column))
    Process.send_after(self(), :play, 500)
    {:noreply, %{column: Integer.mod(column + 1, 7)}}
  end
end
