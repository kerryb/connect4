defmodule Connect4.Bot.SimpleTest do
  use Connect4.DataCase, async: false

  alias Connect4.Auth.Queries.PlayerQueries
  alias Connect4.Bot.Simple
  alias Connect4.Game.Runner

  setup do
    Application.ensure_all_started(:connect4)
    {:ok, _pid} = start_supervised(Runner)
    {:ok, _pid} = start_supervised(Simple)
    :ok
  end

  test "inserts a player record using the code 'bot-simple' if necessary" do
    assert %{name: "Simple Bot"} = PlayerQueries.from_code("bot-simple")
  end
end
