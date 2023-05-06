# credo:disable-for-this-file Credo.Check.Readability.NestedFunctionCalls
defmodule Connect4.Auth.Queries.PlayerQueries do
  @moduledoc """
  Queries for interacting with `Connect4.Auth.Schema.Player` records.
  """

  alias Connect4.Auth.Schema.Player
  alias Connect4.Repo

  @spec all :: [Player.t()]
  def all do
    Repo.all(Player)
  end
end
