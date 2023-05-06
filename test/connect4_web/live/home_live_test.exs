# credo:disable-for-this-file Credo.Check.Readability.OnePipePerLine
# credo:disable-for-this-file Credo.Check.Refactor.VariableRebinding
defmodule Connect4Web.HomeLiveTest do
  use Connect4Web.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Connect4.Auth
  alias Connect4.Auth.Schema.PlayerToken
  alias Connect4.Repo

  describe "Connect4Web.HomeLive" do
    test "Shows a list of confirmed players", %{conn: conn} do
      player_1 = insert(:player, confirmed_at: DateTime.utc_now())
      player_2 = insert(:player, confirmed_at: nil)
      player_3 = insert(:player, confirmed_at: DateTime.utc_now())

      {:ok, view, _html} = conn |> log_in_player(player_1) |> live(~p"/")

      assert view |> element("td", player_1.name) |> has_element?()
      assert view |> element("td", player_3.name) |> has_element?()
      refute view |> element("td", player_2.name) |> has_element?()
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
  end
end
