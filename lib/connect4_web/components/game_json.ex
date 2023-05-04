defmodule Connect4Web.GameJSON do
  alias Connect4.Game.Game

  @spec render(Game.t(), Game.player()) :: map()
  def render(game, player) do
    %{
      playing_as: player,
      next_player: game.next_player,
      board: game.board,
      board_as_array: as_array(game.board)
    }
  end

  defp as_array(board) do
    for column_index <- 0..6 do
      column = Map.get(board, column_index, %{})

      for row_index <- 0..5 do
        column[row_index]
      end
    end
  end
end
