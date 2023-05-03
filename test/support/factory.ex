defmodule Connect4.Factory do
  @moduledoc """
  Factory definitions for tests.
  """

  use ExMachina.Ecto, repo: Connect4.Repo

  def player_factory do
    %Connect4.Game.Schema.Player{
      name: Faker.Person.name(),
      code: Faker.Lorem.characters(20)
    }
  end
end
