defmodule Connect4.Game.Queries.GameQueries do
  @moduledoc """
  Queries for interacting with `Connect4.Game.Schema.Game` records.
  """

  import Ecto.Query

  alias Connect4.Auth.Schema.Player
  alias Connect4.Game.Schema.Game
  alias Connect4.Repo
  alias Ecto.Changeset

  def insert_from_codes(player_o_code, player_x_code) do
    player_o = Repo.one(from(p in Player, where: p.code == ^player_o_code))
    player_x = Repo.one(from(p in Player, where: p.code == ^player_x_code))
    Repo.insert(%Game{player_o: player_o, player_x: player_x})
  end

  def update_winner(id, winner) do
    case Repo.get(Game, id) do
      nil ->
        {:error, "Game not found"}

      game ->
        winner_id = if winner == :O, do: game.player_o_id, else: game.player_x_id
        game |> Changeset.change(%{winner_id: winner_id}) |> Repo.update()
    end
  end
end
