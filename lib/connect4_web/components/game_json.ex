defmodule Connect4Web.GameJSON do
  alias Connect4.Game.Game

  @spec render(Game.t(), Game.player()) :: map()
  def render(game, player) do
    %{
      playing_as: player,
      next_player: game.next_player,
      board: game.board,
      board_as_array: as_array(game.board),
      winner: game.winner,
      status: status(game, player)
    }
  end

  @spec render_test(Game.t()) :: map()
  def render_test(game), do: render(game, game.next_player)

  defp as_array(board) do
    for column_index <- 0..6 do
      column = Map.get(board, column_index, %{})

      for row_index <- 0..5 do
        column[row_index]
      end
    end
  end

  defp status(%{winner: winner}, winner), do: "win"
  defp status(%{winner: :tie}, _player), do: "tie"
  defp status(%{winner: nil}, _player), do: "playing"
  defp status(_winner, _player), do: "lose"
end
