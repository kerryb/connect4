# credo:disable-for-this-file Credo.Check.Readability.OnePipePerLine
# credo:disable-for-this-file Credo.Check.Refactor.VariableRebinding
defmodule Connect4Web.HomeLiveTest do
  use Connect4Web.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Connect4.Auth
  alias Connect4.Auth.Schema.PlayerToken
  alias Connect4.Game.Scheduler
  alias Connect4.Repo
  alias Phoenix.PubSub

  describe "Connect4Web.HomeLive" do
    test "Shows a list of confirmed players, highlighting the logged-in player", %{conn: conn} do
      player_1 = insert(:player, confirmed_at: DateTime.utc_now())
      player_2 = insert(:player, confirmed_at: nil)
      player_3 = insert(:player, confirmed_at: DateTime.utc_now())

      {:ok, view, _html} = conn |> log_in_player(player_1) |> live(~p"/")

      assert view |> element("tr:has(.bg-purple-100) td", player_1.name) |> has_element?()
      assert view |> element("tr:not(has(.bg-purple-100)) td", player_3.name) |> has_element?()
      refute view |> element("tr:not(has(.bg-purple-100)) td", player_2.name) |> has_element?()
    end

    test "Adds newly-confirmed players to the list", %{conn: conn} do
      player = insert(:player, confirmed_at: nil)
      {encoded_token, player_token} = PlayerToken.build_email_token(player, "confirm")
      Repo.insert!(player_token)

      {:ok, view, _html} = live(conn, ~p"/")
      refute view |> element("td", player.name) |> has_element?()

      {:ok, _player} = Auth.confirm_player(encoded_token)
      assert view |> element("td.c4-player", player.name) |> has_element?()
      assert view |> element("td.c4-points", "0") |> has_element?()
    end

    test "allows players to view their codes", %{conn: conn} do
      player = insert(:player, confirmed_at: DateTime.utc_now(), admin: false)
      {:ok, view, _html} = conn |> log_in_player(player) |> live(~p"/")
      refute view |> element("#player-code", player.code) |> has_element?()

      view |> element("a#show-code") |> render_click()
      assert view |> element("#player-code", player.code) |> has_element?()

      view |> element("a#hide-code") |> render_click()
      refute view |> element("#player-code", player.code) |> has_element?()
    end

    test "Allows a player’s game history to be shown", %{conn: conn} do
      player_1 = insert(:player, name: "Alice", confirmed_at: DateTime.utc_now())
      player_2 = insert(:player, name: "Bob", confirmed_at: DateTime.utc_now())

      insert(:game,
        player_o: player_1,
        player_x: player_2,
        winner: "X",
        board: %{0 => %{0 => :O, 1 => :O, 2 => :O, 3 => :O}, 1 => %{0 => :X, 1 => :X, 2 => :X}}
      )

      insert(:game, player_o: player_2, player_x: player_1, winner: "tie", board: %{})

      {:ok, view, _html} = live(conn, ~p"/")
      html = view |> element("tr", "Alice") |> render_click()
      assert html =~ "Bob (X) beat Alice (O)"
      assert html =~ "Bob (O) tied with Alice (X)"

      view |> element("#close-games") |> render_click()
      assert view |> element("h1", "Help") |> has_element?()
    end

    test "Updates scores and re-sorts table as games complete", %{conn: conn} do
      player_1 = insert(:player, name: "Alice", confirmed_at: DateTime.utc_now())
      player_2 = insert(:player, name: "Bob", confirmed_at: DateTime.utc_now())

      {:ok, view, html} = live(conn, ~p"/")

      assert view |> element("tr#player-#{player_1.id} td.c4-played", "0") |> has_element?()
      assert view |> element("tr#player-#{player_1.id} td.c4-won", "0") |> has_element?()
      assert view |> element("tr#player-#{player_1.id} td.c4-tied", "0") |> has_element?()
      assert view |> element("tr#player-#{player_1.id} td.c4-lost", "0") |> has_element?()
      assert view |> element("tr#player-#{player_1.id} td.c4-points", "0") |> has_element?()
      assert html =~ ~r/Alice.*Bob/ms

      game_1 = insert(:game, player_o: player_1, player_x: player_2, winner: "X", board: %{})
      PubSub.broadcast!(Connect4.PubSub, "runner", {:game_finished, game_1})
      game_2 = insert(:game, player_o: player_2, player_x: player_1, winner: "tie", board: %{})
      PubSub.broadcast!(Connect4.PubSub, "runner", {:game_finished, game_2})

      assert view |> element("tr#player-#{player_2.id} td.c4-played", "2") |> has_element?()
      assert view |> element("tr#player-#{player_2.id} td.c4-won", "1") |> has_element?()
      assert view |> element("tr#player-#{player_2.id} td.c4-tied", "1") |> has_element?()
      assert view |> element("tr#player-#{player_2.id} td.c4-points", "4") |> has_element?()
      assert render(view) =~ ~r/Bob.*Alice/ms
    end

    test "Shows an icon when a player has a game in progress", %{conn: conn} do
      player_1 = insert(:player, name: "Alice", confirmed_at: DateTime.utc_now())
      player_2 = insert(:player, name: "Bob", confirmed_at: DateTime.utc_now())
      {:ok, view, _html} = live(conn, ~p"/")
      PubSub.broadcast!(Connect4.PubSub, "runner", :game_started)
      assert view |> element("td.c4-player .hero-bolt:not(.invisible)") |> has_element?()

      game = insert(:game, player_o: player_1, player_x: player_2, winner: "X", board: %{})
      PubSub.broadcast!(Connect4.PubSub, "runner", {:game_finished, game})
      assert view |> element("td.c4-player .hero-bolt.invisible") |> has_element?()
    end

    test "Updates the game list if visible when a game completes", %{conn: conn} do
      player_1 = insert(:player, name: "Alice", confirmed_at: DateTime.utc_now())
      player_2 = insert(:player, name: "Bob", confirmed_at: DateTime.utc_now())

      {:ok, view, _html} = live(conn, ~p"/")
      view |> element("tr", "Alice") |> render_click()

      game = insert(:game, player_o: player_1, player_x: player_2, winner: "X", board: %{})
      PubSub.broadcast!(Connect4.PubSub, "runner", {:game_finished, game})

      assert view |> element("h2", "Bob (X) beat Alice (O)") |> eventually_has_element?()
    end

    test "displays a message if the tournament is inactive", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")
      assert view |> element("#tournament-status", "not currently active") |> has_element?()
    end

    test "displays seconds until next game if the tournament is active", %{conn: conn} do
      Scheduler.activate(10)
      {:ok, view, _html} = live(conn, ~p"/")
      assert view |> element("#tournament-status", ~r/\d+:\d\d/) |> has_element?()
    end

    test "updates the time when it receives a broadcast message", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")
      PubSub.broadcast!(Connect4.PubSub, "scheduler", {:seconds_to_go, 123})
      assert view |> element("#tournament-status", "2:03") |> has_element?()
    end

    test "updates to inactive when it receives a broadcast message", %{conn: conn} do
      Scheduler.activate(10)
      {:ok, view, _html} = live(conn, ~p"/")
      PubSub.broadcast!(Connect4.PubSub, "scheduler", :deactivated)
      assert view |> element("#tournament-status", "not currently active") |> has_element?()
    end

    test "allows admins to enable and disable the tournament", %{conn: conn} do
      admin = insert(:player, confirmed_at: DateTime.utc_now(), admin: true)
      {:ok, view, _html} = conn |> log_in_player(admin) |> live(~p"/")
      view |> element("form#runner") |> render_submit(%{"interval" => "5"})
      assert view |> element("#tournament-status", ~r/\d+:\d\d/) |> eventually_has_element?()
      assert Scheduler.active?()
      assert Scheduler.interval_minutes() == 5

      view |> element("a", "Deactivate") |> render_click()

      assert view
             |> element("#tournament-status", "not currently active")
             |> eventually_has_element?()

      refute Scheduler.active?()
    end

    test "ignores unexpected messages", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")
      send(view.pid, :wibble)
      render(view)
    end
  end
end
