# credo:disable-for-this-file Credo.Check.Readability.NestedFunctionCalls

defmodule Connect4.Game.Queries.GameQueries do
  @moduledoc """
  Queries for interacting with `Connect4.Game.Schema.Game` records.
  """

  import Ecto.Query

  alias Connect4.Auth.Schema.Player
  alias Connect4.Game.Schema.Game
  alias Connect4.Repo
  alias Ecto.Changeset
  alias Ecto.Schema

  @spec insert_from_codes(String.t(), String.t()) :: {:ok, Schema.t()} | {:error, Changeset.t()}
  def insert_from_codes(player_o_code, player_x_code) do
    player_o = Repo.one(from(p in Player, where: p.code == ^player_o_code))
    player_x = Repo.one(from(p in Player, where: p.code == ^player_x_code))
    Repo.insert(%Game{player_o: player_o, player_x: player_x, board: %{}})
  end

  @spec update_winner(integer(), Connect4.Game.Game.player(), Connect4.Game.Game.board()) ::
          {:ok, Schema.t()} | {:error, Changeset.t()} | {:error, String.t()}
  def update_winner(id, winner, board) do
    case Repo.get(Game, id) do
      nil ->
        {:error, "Game not found"}

      game ->
        game
        |> Changeset.change(%{winner: to_string(winner), board: board})
        |> Repo.update()
    end
  end

  @spec delete_all :: {non_neg_integer(), nil | [any()]}
  def delete_all do
    Repo.delete_all(Game)
  end
end
