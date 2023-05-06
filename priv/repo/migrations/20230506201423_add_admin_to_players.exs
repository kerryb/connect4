defmodule Connect4.Repo.Migrations.AddAdminToPlayers do
  use Ecto.Migration

  def change do
    alter table(:players) do
      add(:admin, :boolean, null: false, default: false)
    end
  end
end
