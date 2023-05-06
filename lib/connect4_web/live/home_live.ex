# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Connect4Web.HomeLive do
  @moduledoc false
  use Connect4Web, :live_view

  alias Connect4.Auth.Queries.PlayerQueries
  alias Phoenix.LiveView
  alias Phoenix.PubSub

  @impl LiveView
  def mount(_params, _session, socket) do
    if connected?(socket) do
      PubSub.subscribe(Connect4.PubSub, "players")
    end

    {:ok, assign(socket, players: PlayerQueries.confirmed())}
  end

  @impl LiveView
  def handle_info({:new_player, player}, socket) do
    {:noreply, update(socket, :players, &[player | &1])}
  end
end
