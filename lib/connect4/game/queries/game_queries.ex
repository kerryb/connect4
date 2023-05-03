defmodule Connect4.Game.Queries.GameQueries do
  @moduledoc """
  Queries for interacting with `Connect4.Game.Schema.Game` records.
  """
  import Ecto.Query

  alias Connect4.Game.Schema.{Game, Player}
  alias Connect4.Repo

  def insert_from_codes(player_o_code, player_x_code) do
    player_o = Repo.one(from(p in Player, where: p.code == ^player_o_code))
    player_x = Repo.one(from(p in Player, where: p.code == ^player_x_code))
    Repo.insert(%Game{player_o: player_o, player_x: player_x})
  end
end
