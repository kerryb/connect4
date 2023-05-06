# credo:disable-for-this-file Credo.Check.Readability.OnePipePerLine
# credo:disable-for-this-file Credo.Check.Refactor.VariableRebinding
defmodule Connect4Web.HomeLiveTest do
  use Connect4Web.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "Connect4Web.HomeLive" do
    test "Shows a list of confirmed players", %{conn: conn} do
      player_1 = insert(:player, confirmed_at: DateTime.utc_now())
      player_2 = insert(:player, confirmed_at: nil)
      player_3 = insert(:player, confirmed_at: DateTime.utc_now())

      {:ok, view, _html} =
        conn
        |> log_in_player(player_1)
        |> live(~p"/")

      assert view |> element("td", player_1.name) |> has_element?()
      assert view |> element("td", player_3.name) |> has_element?()
      refute view |> element("td", player_2.name) |> has_element?()
    end
  end
end
