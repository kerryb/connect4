defmodule Connect4.Game.Schema.BoardTest do
  use ExUnit.Case, async: true

  alias Connect4.Game.Schema.Board

  describe "Connect4.Game.Schema.Board.type/0" do
    test "is :map" do
      assert Board.type() == :map
    end
  end

  describe "Connect4.Game.Schema.Board.cast/1" do
    test "passes the board map through as-is" do
      assert Board.cast(%{0 => %{0 => :O}}) == {:ok, %{0 => %{0 => :O}}}
    end
  end

  describe "Connect4.Game.Schema.Board.dump/1" do
    test "passes the board map through as-is" do
      assert Board.dump(%{0 => %{0 => :O}}) == {:ok, %{0 => %{0 => :O}}}
    end
  end

  describe "Connect4.Game.Schema.Board.load/1" do
    test "converts keys to integers and values to atoms" do
      assert Board.load(%{"0" => %{"0" => "O"}}) == {:ok, %{0 => %{0 => :O}}}
    end
  end
end
