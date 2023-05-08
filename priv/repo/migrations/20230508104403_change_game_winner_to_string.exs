defmodule Connect4.Repo.Migrations.ChangeGameWinnerToString do
  use Ecto.Migration

  def change do
    alter table(:games) do
      remove(:winner_id, references("players"))
      add(:winner, :string)
    end
  end
end
