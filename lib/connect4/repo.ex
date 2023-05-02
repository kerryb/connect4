defmodule Connect4.Repo do
  use Ecto.Repo,
    otp_app: :connect4,
    adapter: Ecto.Adapters.Postgres
end
