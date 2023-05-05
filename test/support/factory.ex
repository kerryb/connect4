defmodule Connect4.Factory do
  @moduledoc """
  Factory definitions for tests.
  """

  use ExMachina.Ecto, repo: Connect4.Repo

  alias Connect4.Auth.Schema.Player
  alias Connect4.Game.Schema.Game
  alias Ecto.Changeset

  def player_factory do
    %Player{}
    |> Player.registration_changeset(%{
      email: Faker.Internet.email(),
      name: Faker.Person.name(),
      password: Faker.String.base64(12)
    })
    |> Changeset.apply_action!(:dummy)
  end

  def game_factory do
    %Game{
      player_o: build(:player),
      player_x: build(:player)
    }
  end
end
