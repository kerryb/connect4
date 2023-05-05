defmodule Connect4.Game.Schema.Game do
  @moduledoc """
  Details of a game, which may be in progress or completed.
  """
  use Ecto.Schema

  alias Connect4.Auth.Schema.Player

  schema "games" do
    belongs_to(:player_o, Player)
    belongs_to(:player_x, Player)
    belongs_to(:winner, Player)
    timestamps(type: :utc_datetime)
  end
end
