# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Connect4Web.HomeLive do
  @moduledoc false
  use Connect4Web, :live_view

  alias Connect4.Auth.Queries.PlayerQueries
  alias Connect4.Auth.Schema.Player
  alias Connect4.Game.Scheduler
  alias Phoenix.LiveView
  alias Phoenix.PubSub

  @impl LiveView
  def mount(_params, _session, socket) do
    if connected?(socket) do
      PubSub.subscribe(Connect4.PubSub, "runner")
      PubSub.subscribe(Connect4.PubSub, "players")
      PubSub.subscribe(Connect4.PubSub, "scheduler")
    end

    players = Enum.map(PlayerQueries.active_with_games(), &Player.calculate_stats(&1))
    active? = Scheduler.active?()
    interval_minutes = Scheduler.interval_minutes()

    time_until_next_game =
      if active? do
        format_time(Scheduler.seconds_to_go())
      end

    {:ok,
     assign(socket,
       players: players,
       active?: active?,
       interval_minutes: interval_minutes,
       time_until_next_game: time_until_next_game
     )}
  end

  @impl LiveView
  def handle_event("activate", params, socket) do
    params["interval"]
    |> String.to_integer()
    |> Scheduler.activate()

    {:noreply, assign(socket, active?: true)}
  end

  def handle_event("deactivate", _params, socket) do
    Scheduler.deactivate()
    {:noreply, assign(socket, active?: false)}
  end

  @impl LiveView
  def handle_info({:new_player, player}, socket) do
    {:noreply, update(socket, :players, &[Player.calculate_stats(player) | &1])}
  end

  def handle_info({:game_finished, game}, socket) do
    {:noreply, update(socket, :players, &update_players(&1, game))}
  end

  def handle_info({:seconds_to_go, seconds_to_go}, socket) do
    {:noreply, assign(socket, active?: true, time_until_next_game: format_time(seconds_to_go))}
  end

  def handle_info(:deactivated, socket) do
    {:noreply, assign(socket, active?: false)}
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  defp update_players(players, game) do
    players
    |> Enum.map(&update_player(&1, game))
    |> Enum.sort_by(&{-&1.points, -&1.won, &1.name})
  end

  defp update_player(player, game) do
    if player.id in [game.player_o_id, game.player_x_id] do
      PlayerQueries.reload_player_with_game_and_stats(player.id)
    else
      player
    end
  end

  defp format_time(seconds_to_go) do
    minutes = div(seconds_to_go, 60)

    seconds =
      seconds_to_go
      |> Integer.mod(60)
      |> to_string()
      |> String.pad_leading(2, "0")

    "#{minutes}:#{seconds}"
  end
end
