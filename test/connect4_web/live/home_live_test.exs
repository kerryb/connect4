# credo:disable-for-this-file Credo.Check.Readability.OnePipePerLine
# credo:disable-for-this-file Credo.Check.Refactor.VariableRebinding
defmodule Connect4Web.HomeLiveTest do
  use Connect4Web.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Connect4.Auth
  alias Connect4.Auth.Schema.PlayerToken
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
      player_1 = insert(:player, confirmed_at: DateTime.utc_now())
      player_2 = insert(:player, confirmed_at: nil)
      {encoded_token, player_token} = PlayerToken.build_email_token(player_2, "confirm")
      Repo.insert!(player_token)

      {:ok, view, _html} = conn |> log_in_player(player_1) |> live(~p"/")
      refute view |> element("td", player_2.name) |> has_element?()

      {:ok, _player} = Auth.confirm_player(encoded_token)
      assert view |> element("td", player_2.name) |> has_element?()
    end

    test "Updates scores as games complete", %{conn: conn} do
      player_1 = insert(:player, confirmed_at: DateTime.utc_now())
      player_2 = insert(:player, confirmed_at: DateTime.utc_now())

      {:ok, view, _html} = conn |> log_in_player(player_1) |> live(~p"/")

      assert view |> element("tr#player-#{player_1.id} td.c4-played", "0") |> has_element?()
      assert view |> element("tr#player-#{player_1.id} td.c4-won", "0") |> has_element?()
      assert view |> element("tr#player-#{player_1.id} td.c4-tied", "0") |> has_element?()
      assert view |> element("tr#player-#{player_1.id} td.c4-lost", "0") |> has_element?()

      game_1 = insert(:game, player_o: player_1, player_x: player_2, winner: "O", board: %{})
      PubSub.broadcast!(Connect4.PubSub, "games", {:completed, game_1})
      game_2 = insert(:game, player_o: player_2, player_x: player_1, winner: "tie", board: %{})
      PubSub.broadcast!(Connect4.PubSub, "games", {:completed, game_2})

      assert view |> element("tr#player-#{player_1.id} td.c4-played", "2") |> has_element?()
      assert view |> element("tr#player-#{player_1.id} td.c4-won", "1") |> has_element?()
      assert view |> element("tr#player-#{player_1.id} td.c4-tied", "1") |> has_element?()
      assert view |> element("tr#player-#{player_2.id} td.c4-lost", "1") |> has_element?()
    end

    test "says if the tournament is currently inactive", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")
      assert html =~ "not currently active"
    end
  end
end
