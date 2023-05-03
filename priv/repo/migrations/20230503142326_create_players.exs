defmodule Connect4.Repo.Migrations.CreatePlayers do
  use Ecto.Migration

  def change do
    create table(:players) do
      add(:name, :text, null: false)
      add(:code, :text, null: false)
      timestamps()
    end

    create unique_index(:players, :name)
    create unique_index(:players, :code)
  end
end
