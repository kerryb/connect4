# credo:disable-for-this-file Credo.Check.Readability.OnePipePerLine
# credo:disable-for-this-file Credo.Check.Refactor.VariableRebinding
defmodule Connect4Web.HomeLiveTest do
  use Connect4Web.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "Connect4Web.HomeLive" do
    test "Show a list of players", %{conn: conn} do
      player_1 = insert(:player)
      player_2 = insert(:player)

      {:ok, view, _html} =
        conn
        |> log_in_player(player_1)
        |> live(~p"/")

      assert view |> element("td", player_1.name) |> has_element?()
      assert view |> element("td", player_2.name) |> has_element?()
    end
  end
end
