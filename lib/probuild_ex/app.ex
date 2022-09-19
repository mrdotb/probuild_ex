defmodule ProbuildEx.App do
  @moduledoc """
  The context module who hold the queries.
  """

  import Ecto.Query

  alias ProbuildEx.Repo

  alias ProbuildEx.Games.Participant

  def list_pro_participant_summoner(_opts) do
    query =
      from participant in Participant,
        left_join: game in assoc(participant, :game),
        left_join: summoner in assoc(participant, :summoner),
        left_join: opponent_participant in assoc(participant, :opponent_participant),
        inner_join: pro in assoc(summoner, :pro),
        preload: [
          game: game,
          opponent_participant: opponent_participant,
          summoner: {summoner, pro: pro}
        ],
        order_by: [desc: game.creation],
        limit: 20

    Repo.all(query)
  end
end
