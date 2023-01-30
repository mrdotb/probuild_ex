defmodule ProbuildEx.App do
  @moduledoc """
  The context module who hold the queries.
  """

  import Ecto.Query

  alias ProbuildEx.Repo
  alias ProbuildEx.Ddragon

  alias ProbuildEx.Games.{Game, Participant}

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
      inner_join: game in assoc(participant, :game),
      as: :game,
      inner_join: summoner in assoc(participant, :summoner),
      inner_join: opponent_participant in assoc(participant, :opponent_participant),
      inner_join: pro in assoc(summoner, :pro),
      as: :pro,
      preload: [
        game: game,
        opponent_participant: opponent_participant,
        summoner: {summoner, pro: pro}
      ],
      order_by: [desc: game.creation]
  end

  @doc """
  Fetch pro participant based on search_opts.
  """
  def fetch_pro_participant(search_opts) do
    query = Enum.reduce(search_opts, pro_participant_base_query(), &reduce_pro_participant_opts/2)

    case Repo.one(query) do
      nil -> {:error, :not_found}
      participant -> {:ok, participant}
    end
  end

  @doc """
  Query pro participant paginated based on search_opts.
  """
  def paginate_pro_participants(search_opts, after_cursor \\ nil) do
    query = Enum.reduce(search_opts, pro_participant_base_query(), &reduce_pro_participant_opts/2)

    opts = [
      cursor_fields: [{{:game, :creation}, :desc}],
      after: after_cursor
    ]

    Repo.paginate(query, opts)
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
    champions_ids =
      Enum.reduce(Ddragon.get_champions_search_map(), [], fn {champion_name, champion_id}, acc ->
        if String.starts_with?(champion_name, search) do
          [champion_id | acc]
        else
          acc
        end
      end)

    search_str = search <> "%"

    from [participant, pro: pro] in query,
      where: ilike(pro.name, ^search_str) or participant.champion_id in ^champions_ids
  end

  defp reduce_pro_participant_opts({:participant_id, participant_id}, query) do
    from participant in query,
      where: participant.id == ^participant_id
  end

  defp reduce_pro_participant_opts({key, value}, _query),
    do: raise("not supported option #{inspect(key)} with value #{inspect(value)}")

  @doc """
  Fetch game complete per game_id.
  """
  def fetch_game(game_id) do
    query =
      from game in Game,
        left_join: participants in assoc(game, :participants),
        left_join: summoners in assoc(participants, :summoner),
        preload: [
          participants: {participants, summoner: summoners}
        ],
        where: game.id == ^game_id,
        order_by: [
          asc: participants.team_id,
          asc:
            fragment(
              "array_position(ARRAY['TOP', 'JUNGLE', 'MIDDLE', 'TOP', 'UTILITY'], ?)",
              participants.team_position
            )
        ]

    case Repo.one(query) do
      nil -> {:error, :not_found}
      game -> {:ok, game}
    end
  end
end
