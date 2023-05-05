defmodule Connect4Web.PlayerConfirmationLiveTest do
  use Connect4Web.ConnCase

  import Connect4.AuthFixtures
  import Phoenix.LiveViewTest

  alias Connect4.Auth
  alias Connect4.Auth.Schema.PlayerToken
  alias Connect4.Repo

  setup do
    %{player: player_fixture()}
  end

  describe "Confirm player" do
    test "renders confirmation page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/players/confirm/some-token")
      assert html =~ "Confirm Account"
    end

    test "confirms the given token once", %{conn: conn, player: player} do
      token =
        extract_player_token(fn url ->
          Auth.deliver_player_confirmation_instructions(player, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/players/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Player confirmed successfully"

      assert Auth.get_player!(player.id).confirmed_at
      refute get_session(conn, :player_token)
      assert Repo.all(PlayerToken) == []

      # when not logged in
      {:ok, lv, _html} = live(conn, ~p"/players/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Player confirmation link is invalid or it has expired"

      # when logged in
      {:ok, lv, _html} =
        build_conn()
        |> log_in_player(player)
        |> live(~p"/players/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result
      refute Phoenix.Flash.get(conn.assigns.flash, :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, player: player} do
      {:ok, lv, _html} = live(conn, ~p"/players/confirm/invalid-token")

      {:ok, conn} =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Player confirmation link is invalid or it has expired"

      refute Auth.get_player!(player.id).confirmed_at
    end
  end
end
