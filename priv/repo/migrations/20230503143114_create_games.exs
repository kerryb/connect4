defmodule Connect4.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games) do
      add(:player_o_id, references("players"))
      add(:player_x_id, references("players"))
      add(:winner_id, references("players"))
      timestamps()
    end
  end
end
