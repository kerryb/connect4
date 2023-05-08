defmodule Connect4.Game.Schema.Game do
  @moduledoc """
  Details of a game, which may be in progress or completed.
  """
  use Ecto.Schema

  alias Connect4.Auth.Schema.Player
  alias Connect4.Game.Schema.Board

  @type t :: %__MODULE__{}

  schema "games" do
    field(:board, Board)
    belongs_to(:player_o, Player)
    belongs_to(:player_x, Player)
    field(:winner, :string)
    timestamps(type: :utc_datetime)
  end
end
