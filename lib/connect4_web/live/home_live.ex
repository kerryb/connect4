# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Connect4Web.HomeLive do
  @moduledoc false
  use Connect4Web, :live_view

  alias Connect4.Auth.Queries.PlayerQueries

  def mount(_params, _session, socket) do
    {:ok, assign(socket, players: PlayerQueries.all())}
  end
end
