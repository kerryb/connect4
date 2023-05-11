# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Connect4Web.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use Connect4Web.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      use Connect4Web, :verified_routes

      # Import conveniences for testing with connections
      import Connect4.Factory
      import Connect4Web.ConnCase
      import Phoenix.ConnTest
      import Plug.Conn

      @endpoint Connect4Web.Endpoint
    end
  end

  setup tags do
    Connect4.DataCase.setup_sandbox(tags)
    {:ok, _pid} = start_supervised(Connect4.Game.Scheduler)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Setup helper that registers and logs in players.

      setup :register_and_log_in_player

  It stores an updated connection and a registered player in the
  test context.
  """
  def register_and_log_in_player(%{conn: conn}) do
    player = Connect4.AuthFixtures.player_fixture()
    %{conn: log_in_player(conn, player), player: player}
  end

  @doc """
  Logs the given `player` into the `conn`.

  It returns an updated `conn`.
  """
  def log_in_player(conn, player) do
    token = Connect4.Auth.generate_player_session_token(player)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:player_token, token)
  end

  @doc """
  Look for an element for up to a second, giving the view a chance to re-render
  after asynchronous operations.

  Usage is the same as `Phoenix.LiveViewTest.has_element?/1`.
  """
  @spec eventually_has_element?(Phoenix.LiveViewTest.Element.t()) :: boolean()
  def eventually_has_element?(element, retries \\ 0)
  def eventually_has_element?(_element, 20), do: false

  def eventually_has_element?(element, retries) do
    if Phoenix.LiveViewTest.has_element?(element) do
      true
    else
      Process.sleep(100)
      eventually_has_element?(element, retries + 1)
    end
  end

  @doc """
  Look for the absence of an element for up to a second, giving the view a
  chance to re-render after asynchronous operations.

  Usage is the same as `Phoenix.LiveViewTest.has_element?/1`.
  """
  @spec eventually_has_no_element?(Phoenix.LiveViewTest.Element.t()) :: boolean()
  def eventually_has_no_element?(element, retries \\ 0)
  def eventually_has_no_element?(_element, 20), do: false

  def eventually_has_no_element?(element, retries) do
    if Phoenix.LiveViewTest.has_element?(element) do
      Process.sleep(100)
      eventually_has_no_element?(element, retries + 1)
    else
      true
    end
  end
end
