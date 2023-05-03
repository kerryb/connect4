defmodule Connect4.Factory do
  @moduledoc """
  Factory definitions for tests.
  """

  use ExMachina.Ecto, repo: Connect4.Repo

  def player_factory do
    %Connect4.Game.Schema.Player{
      name: Faker.Person.name(),
      code: Faker.Lorem.sentence(4)
    }
  end

  def game_factory do
    %Connect4.Game.Schema.Game{
      player_o: build(:player),
      player_x: build(:player)
    }
  end
end
