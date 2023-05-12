# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Connect4Web.HelpLive do
  @moduledoc false
  use Connect4Web, :live_view

  alias Phoenix.LiveView

  @impl LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
