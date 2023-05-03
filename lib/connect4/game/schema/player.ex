defmodule Connect4.Game.Schema.Player do
  @moduledoc """
  Details of a player (or pair, team etc).

  A unique code is generated for each player, which will map to their personal
  API URL.
  """
  use Ecto.Schema

  schema "players" do
    field :name, :string
    field :code, :string
    timestamps(type: :utc_datetime)
  end
end
