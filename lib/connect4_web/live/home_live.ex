# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Connect4Web.HomeLive do
  @moduledoc false
  use Connect4Web, :live_view

  alias Connect4.Auth.Queries.PlayerQueries
  alias Connect4.Auth.Schema.Player
  alias Phoenix.LiveView
  alias Phoenix.PubSub

  @impl LiveView
  def mount(_params, _session, socket) do
    if connected?(socket) do
      PubSub.subscribe(Connect4.PubSub, "games")
      PubSub.subscribe(Connect4.PubSub, "players")
    end

    players = Enum.map(PlayerQueries.active_with_games(), &Player.calculate_stats(&1))
    {:ok, assign(socket, players: players)}
  end

  @impl LiveView
  def handle_info({:new_player, player}, socket) do
    {:noreply, update(socket, :players, &[player | &1])}
  end

  def handle_info({:completed, game}, socket) do
    {:noreply, update(socket, :players, &update_players(&1, game))}
  end

  defp update_players(players, game), do: Enum.map(players, &update_player(&1, game))

  defp update_player(player, game) do
    if player.id in [game.player_o_id, game.player_x_id] do
      PlayerQueries.reload_player_with_game_and_stats(player.id)
    else
      player
    end
  end
end
