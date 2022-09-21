defmodule ProbuildEx.App do
  @moduledoc """
  The context module who hold the queries.
  """

  import Ecto.Query

  alias ProbuildEx.Repo

  alias ProbuildEx.Games.Participant

  defmodule Search do
    @moduledoc """
    We represent our search input in a embedded_schema to use ecto validation
    helpers.
    """

    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false

    embedded_schema do
      field :search, :string
      field :platform_id, Ecto.Enum, values: [:euw1, :jp1, :kr, :na1, :br1]
      field :team_position, Ecto.Enum, values: [:UTILITY, :TOP, :JUNGLE, :MIDDLE, :BOTTOM]
    end

    def changeset(search \\ %__MODULE__{}, attrs \\ %{}) do
      cast(search, attrs, [:search, :platform_id, :team_position])
    end

    def validate(changeset) do
      apply_action(changeset, :insert)
    end

    def to_map(search) do
      Map.from_struct(search)
    end

    def platform_options do
      Ecto.Enum.values(__MODULE__, :platform_id)
    end
  end

  defp pro_participant_base_query do
    from participant in Participant,
      left_join: game in assoc(participant, :game),
      as: :game,
      left_join: summoner in assoc(participant, :summoner),
      left_join: opponent_participant in assoc(participant, :opponent_participant),
      inner_join: pro in assoc(summoner, :pro),
      as: :pro,
      preload: [
        game: game,
        opponent_participant: opponent_participant,
        summoner: {summoner, pro: pro}
      ],
      order_by: [desc: game.creation],
      limit: 20
  end

  def list_pro_participant_summoner(search_opts) do
    query = Enum.reduce(search_opts, pro_participant_base_query(), &reduce_pro_participant_opts/2)

    Repo.all(query)
  end

  defp reduce_pro_participant_opts({:platform_id, nil}, query) do
    query
  end

  defp reduce_pro_participant_opts({:platform_id, platform_id}, query) do
    from [participant, game: game] in query,
      where: game.platform_id == ^platform_id
  end

  defp reduce_pro_participant_opts({:team_position, nil}, query) do
    query
  end

  defp reduce_pro_participant_opts({:team_position, team_position}, query) do
    from [participant] in query,
      where: participant.team_position == ^team_position
  end

  defp reduce_pro_participant_opts({:search, nil}, query) do
    query
  end

  defp reduce_pro_participant_opts({:search, search}, query) do
    search_str = search <> "%"

    from [participant, pro: pro] in query,
      where: ilike(pro.name, ^search_str)
  end

  defp reduce_pro_participant_opts({key, value}, _query),
    do: raise("not supported option #{inspect(key)} with value #{inspect(value)}")
end
