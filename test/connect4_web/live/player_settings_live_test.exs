# credo:disable-for-this-file Credo.Check.Readability.OnePipePerLine
# credo:disable-for-this-file Credo.Check.Refactor.VariableRebinding
defmodule Connect4Web.PlayerSettingsLiveTest do
  use Connect4Web.ConnCase, async: false

  import Connect4.AuthFixtures
  import Phoenix.LiveViewTest

  alias Connect4.Auth
  alias Connect4.Auth.Schema.PlayerToken
  alias Connect4.Repo
  alias Phoenix.Flash

  describe "Settings page" do
    test "renders settings page", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_player(player_fixture())
        |> live(~p"/players/settings")

      assert html =~ "Change Email"
      assert html =~ "Change Password"
    end

    test "redirects if player is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/players/settings")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/players/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end

  describe "resend confirmation email button" do
    test "sends a new confirmation token", %{conn: conn} do
      player = player_fixture()

      {:ok, lv, _html} =
        conn
        |> log_in_player(player)
        |> live(~p"/players/settings")

      Repo.delete_all(PlayerToken)
      lv |> element("button", "Resend Confirmation Email") |> render_click()
      assert lv |> element("#flash", "If your email is in our system") |> has_element?()
      assert Repo.get_by!(PlayerToken, player_id: player.id).context == "confirm"
    end
  end

  describe "regenerate code button" do
    test "sets a new code", %{conn: conn} do
      player = player_fixture()

      {:ok, lv, _html} =
        conn
        |> log_in_player(player)
        |> live(~p"/players/settings")

      lv |> element("button", "Regenerate Player Code") |> render_click()
      assert lv |> element("#flash", "Your player code has been regenerated") |> has_element?()
      refute player.code == Repo.reload!(player).code
    end
  end

  describe "update email form" do
    setup %{conn: conn} do
      password = valid_player_password()
      player = player_fixture(%{password: password})
      %{conn: log_in_player(conn, player), player: player, password: password}
    end

    test "updates the player email", %{conn: conn, password: password, player: player} do
      new_email = unique_player_email()

      {:ok, lv, _html} = live(conn, ~p"/players/settings")

      result =
        lv
        |> form("#email_form", %{
          "current_password" => password,
          "player" => %{"email" => new_email}
        })
        |> render_submit()

      assert result =~ "A link to confirm your email"
      assert Auth.get_player_by_email(player.email)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/players/settings")

      result =
        lv
        |> element("#email_form")
        |> render_change(%{
          "action" => "update_email",
          "current_password" => "invalid",
          "player" => %{"email" => "with spaces"}
        })

      assert result =~ "Change Email"
      assert result =~ "must have the @ sign and no spaces"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn, player: player} do
      {:ok, lv, _html} = live(conn, ~p"/players/settings")

      result =
        lv
        |> form("#email_form", %{
          "current_password" => "invalid",
          "player" => %{"email" => player.email}
        })
        |> render_submit()

      assert result =~ "Change Email"
      assert result =~ "did not change"
      assert result =~ "is not valid"
    end
  end

  describe "update password form" do
    setup %{conn: conn} do
      password = valid_player_password()
      player = player_fixture(%{password: password})
      %{conn: log_in_player(conn, player), player: player, password: password}
    end

    test "updates the player password", %{conn: conn, player: player, password: password} do
      new_password = valid_player_password()

      {:ok, lv, _html} = live(conn, ~p"/players/settings")

      form =
        form(lv, "#password_form", %{
          "current_password" => password,
          "player" => %{
            "email" => player.email,
            "password" => new_password,
            "password_confirmation" => new_password
          }
        })

      render_submit(form)

      new_password_conn = follow_trigger_action(form, conn)

      assert redirected_to(new_password_conn) == ~p"/players/settings"

      assert get_session(new_password_conn, :player_token) != get_session(conn, :player_token)

      assert Flash.get(new_password_conn.assigns.flash, :info) =~
               "Password updated successfully"

      assert Auth.get_player_by_email_and_password(player.email, new_password)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/players/settings")

      result =
        lv
        |> element("#password_form")
        |> render_change(%{
          "current_password" => "invalid",
          "player" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/players/settings")

      result =
        lv
        |> form("#password_form", %{
          "current_password" => "invalid",
          "player" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })
        |> render_submit()

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
      assert result =~ "is not valid"
    end
  end

  describe "confirm email" do
    setup %{conn: conn} do
      player = player_fixture()
      email = unique_player_email()

      token =
        extract_player_token(fn url ->
          Auth.deliver_player_update_email_instructions(
            %{player | email: email},
            player.email,
            url
          )
        end)

      %{conn: log_in_player(conn, player), token: token, email: email, player: player}
    end

    test "updates the player email once", %{
      conn: conn,
      player: player,
      token: token,
      email: email
    } do
      {:error, redirect} = live(conn, ~p"/players/settings/confirm_email/#{token}")

      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/players/settings"
      assert %{"info" => message} = flash
      assert message == "Email changed successfully."
      refute Auth.get_player_by_email(player.email)
      assert Auth.get_player_by_email(email)

      # use confirm token again
      {:error, redirect} = live(conn, ~p"/players/settings/confirm_email/#{token}")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/players/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
    end

    test "does not update email with invalid token", %{conn: conn, player: player} do
      {:error, redirect} = live(conn, ~p"/players/settings/confirm_email/oops")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/players/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
      assert Auth.get_player_by_email(player.email)
    end

    test "redirects if player is not logged in", %{token: token} do
      conn = build_conn()
      {:error, redirect} = live(conn, ~p"/players/settings/confirm_email/#{token}")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/players/log_in"
      assert %{"error" => message} = flash
      assert message == "You must log in to access this page."
    end
  end
end
