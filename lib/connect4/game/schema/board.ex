defmodule Connect4.Game.Schema.Board do
  @moduledoc """
  Custom Ecto type, allowing a board (nested map of column numbers to player
  atoms, eg `%{0 => %{0 => :O, 1 => :X}}`) to be stored in the database.
  """
  use Ecto.Type

  alias Ecto.Type

  @impl Type
  def type, do: :map

  @impl Type
  def cast(board), do: {:ok, board}

  @impl Type
  def dump(board), do: {:ok, board}

  @impl Type
  def load(data), do: {:ok, Enum.into(data, %{}, &restore_types/1)}

  defp restore_types({key, value}) when is_binary(value) do
    # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
    {String.to_integer(key), String.to_atom(value)}
  end

  defp restore_types({key, value}) do
    {String.to_integer(key), Enum.into(value, %{}, &restore_types/1)}
  end
end
