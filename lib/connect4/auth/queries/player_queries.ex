# credo:disable-for-this-file Credo.Check.Readability.NestedFunctionCalls
defmodule Connect4.Auth.Queries.PlayerQueries do
  @moduledoc """
  Queries for interacting with `Connect4.Auth.Schema.Player` records.
  """

  import Ecto.Query

  alias Connect4.Auth.Schema.Player
  alias Connect4.Repo

  @spec active :: [Player.t()]
  def active do
    Repo.all(from(p in Player, where: not is_nil(p.confirmed_at), where: not p.admin))
  end

  @spec active_with_games :: [Player.t()]
  def active_with_games do
    Repo.all(
      from(p in Player,
        where: not is_nil(p.confirmed_at),
        where: not p.admin,
        preload: [:games_as_o, :games_as_x]
      )
    )
  end

  @spec reload_player_with_game_and_stats(integer()) :: Player.t()
  def reload_player_with_game_and_stats(id) do
    from(p in Player, where: p.id == ^id, preload: [:games_as_o, :games_as_x])
    |> Repo.one()
    |> Player.calculate_stats()
  end
end
