# credo:disable-for-this-file Credo.Check.Readability.NestedFunctionCalls
defmodule Connect4.Auth.Queries.PlayerQueries do
  @moduledoc """
  Queries for interacting with `Connect4.Auth.Schema.Player` records.
  """

  import Ecto.Query

  alias Connect4.Auth.Schema.Player
  alias Connect4.Repo

  @spec confirmed :: [Player.t()]
  def confirmed do
    Repo.all(from(p in Player, where: not is_nil(p.confirmed_at), where: not p.admin))
  end
end
