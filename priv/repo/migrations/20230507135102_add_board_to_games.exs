defmodule Connect4.Repo.Migrations.AddBoardToGames do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add(:board, :map)
    end
  end
end
