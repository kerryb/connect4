defmodule Connect4.AuthFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Connect4.Auth` context.
  """

  def unique_player_email, do: "player#{System.unique_integer()}@example.com"
  def valid_player_password, do: "hello world!"
  def valid_player_name, do: "player#{System.unique_integer()}"

  def valid_player_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_player_email(),
      password: valid_player_password(),
      name: valid_player_name()
    })
  end

  def player_fixture(attrs \\ %{}) do
    {:ok, player} =
      attrs
      |> valid_player_attributes()
      |> Connect4.Auth.register_player()

    player
  end

  def extract_player_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
