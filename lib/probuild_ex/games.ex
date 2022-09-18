defmodule ProbuildEx.Games do
  @moduledoc """
  The context module to manage the creation / updates of schemas.
  """

  import Ecto.Query

  alias Ecto.Multi
  alias ProbuildEx.Repo

  alias ProbuildEx.Games.{
    Game,
    Participant,
    Pro,
    Summoner,
    Team
  }

  @doc """
  Create a Pro with his team and summoner inside a transaction.
  """
  def create_pro_complete(ugg_pro, summoner_data) do
    Repo.transaction(fn ->
      with {:ok, team} <- fetch_or_create_team(ugg_pro["current_team"]),
           {:ok, pro} <- fetch_or_create_pro(ugg_pro["official_name"], team.id),
           attrs <-
             Map.merge(summoner_data, %{
               "platform_id" => ugg_pro["region_id"],
               "pro_id" => pro.id
             }),
           {:ok, summoner} <- update_or_create_summoner(attrs) do
        %{team: team, pro: pro, summoner: summoner}
      else
        {:error, error} -> Repo.rollback(error)
      end
    end)
  end

  @doc """
  Fetch or create a team based on name.
  """
  def fetch_or_create_team(name) do
    case Repo.get_by(Team, name: name) do
      nil ->
        changeset = Team.changeset(%Team{}, %{name: name})
        Repo.insert(changeset)

      team ->
        {:ok, team}
    end
  end

  @doc """
  Fetch or create a pro based on name and team_id.
  """
  def fetch_or_create_pro(name, team_id) do
    case Repo.get_by(Pro, name: name, team_id: team_id) do
      nil ->
        changeset = Pro.changeset(%Pro{}, %{name: name, team_id: team_id})
        Repo.insert(changeset)

      pro ->
        {:ok, pro}
    end
  end

  @doc """
  Fetch a summoner using options.

  Options:

    * `name`
    * `puuid`
    * `platform_id`
    * `is_pro?`

  ## Example

      iex> Games.fetch_summoner(name: "Hide on bush", is_pro?: true)
      {:ok, %Summoner{}}

      iex> Games.fetch_summoner(name: "Hide on bush", is_pro?: false)
      {:error, :not_found}
  """
  def fetch_summoner(opts) do
    base_query = from(summoner in Summoner)
    query = Enum.reduce(opts, base_query, &reduce_summoner_opts/2)

    case Repo.one(query) do
      nil -> {:error, :not_found}
      summoner -> {:ok, summoner}
    end
  end

  defp reduce_summoner_opts({:name, name}, query) do
    from summoner in query,
      where: summoner.name == ^name
  end

  defp reduce_summoner_opts({:puuid, puuid}, query) do
    from summoner in query,
      where: summoner.puuid == ^puuid
  end

  defp reduce_summoner_opts({:platform_id, platform_id}, query) do
    from summoner in query,
      where: summoner.platform_id == ^platform_id
  end

  defp reduce_summoner_opts({:is_pro?, true}, query) do
    from summoner in query,
      where: not is_nil(summoner.pro_id)
  end

  defp reduce_summoner_opts({:is_pro?, false}, query) do
    from summoner in query,
      where: is_nil(summoner.pro_id)
  end

  defp reduce_summoner_opts({key, value}, _query),
    do: raise("not supported option #{inspect(key)} with value #{inspect(value)}")

  @doc """
  Create summoner
  """
  def create_summoner(attrs) do
    %Summoner{}
    |> Summoner.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Update summoner
  """
  def update_summoner(summoner, attrs) do
    summoner
    |> Summoner.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Update or Create summoner
  """
  def update_or_create_summoner(attrs) do
    opts = [puuid: attrs["puuid"], platform_id: attrs["platform_id"]]

    case fetch_summoner(opts) do
      {:ok, summoner} ->
        update_summoner(summoner, attrs)

      {:error, :not_found} ->
        create_summoner(attrs)
    end
  end

  @doc """
  List pro summoner per platform_id.
  """
  def list_pro_summoners(platform_id) do
    query =
      from summoner in Summoner,
        where: summoner.platform_id == ^platform_id and not is_nil(summoner.pro_id),
        order_by: [desc: summoner.updated_at]

    Repo.all(query)
  end

  @doc """
  Given a list of riots ids return a list of the one that does not exist in database yet
  """
  def reject_existing_games(riot_ids) do
    query =
      from game in Game,
        where: game.riot_id in ^riot_ids,
        select: game.riot_id

    existing_riot_ids = Repo.all(query)
    Enum.reject(riot_ids, fn riot_id -> riot_id in existing_riot_ids end)
  end

  @doc """
  Create a complete game based on a platform_id, match_data and a list of summoners.
  """
  def create_game_complete(platform_id, match_data, summoners_list) do
    multi = Multi.insert(Multi.new(), :game, change_game(match_data))

    multi =
      Enum.reduce(summoners_list, multi, fn summoner, multi ->
        reduce_put_or_create_summoner(platform_id, summoner, multi)
      end)

    participants = get_in(match_data, ["info", "participants"])

    multi = Enum.reduce(participants, multi, &reduce_create_participant/2)
    multi = Enum.reduce(participants, multi, &reduce_set_opponent_participant/2)

    Repo.transaction(multi)
  end

  defp reduce_put_or_create_summoner(_platform_id, %Summoner{} = summoner, multi) do
    Multi.put(multi, {:summoner, summoner.puuid}, summoner)
  end

  defp reduce_put_or_create_summoner(platform_id, summoner_data, multi) do
    case Map.fetch(summoner_data, "puuid") do
      {:ok, puuid} ->
        attrs = Map.put(summoner_data, "platform_id", platform_id)
        changeset = Summoner.changeset(%Summoner{}, attrs)
        Multi.insert(multi, {:summoner, puuid}, changeset)

      :error ->
        multi
    end
  end

  defp fetch_participant_key(participant_data) do
    with {:ok, team_id} <- Map.fetch(participant_data, "teamId"),
         true <- team_id in [100, 200],
         {:ok, team_position} <- Map.fetch(participant_data, "teamPosition"),
         true <-
           is_binary(team_position) and
             team_position in ["UTILITY", "TOP", "JUNGLE", "MIDDLE", "BOTTOM"] do
      {:ok, {team_id, team_position}}
    else
      _ ->
        :error
    end
  end

  defp get_enemy_team_id(100), do: 200
  defp get_enemy_team_id(200), do: 100

  defp fetch_opponent_participant_key(participant_data) do
    with {:ok, {team_id, team_position}} <- fetch_participant_key(participant_data),
         enemy_team_id <- get_enemy_team_id(team_id) do
      {:ok, {enemy_team_id, team_position}}
    else
      _ ->
        :error
    end
  end

  defp reduce_create_participant(participant_data, multi) do
    result = fetch_participant_key(participant_data)
    reduce_create_participant(result, participant_data, multi)
  end

  defp reduce_create_participant({:ok, participant_key}, participant_data, multi) do
    Multi.insert(
      multi,
      {:participant, participant_key},
      fn changes ->
        case Map.fetch(changes, {:summoner, participant_data["puuid"]}) do
          {:ok, summoner} ->
            change_participant(changes.game, participant_data, summoner)

          :error ->
            # If we can't find the summoner in the changes we put a changeset with
            # error. It will make the multi fail.
            Ecto.Changeset.add_error(%Ecto.Changeset{}, :summoner, "not_found")
        end
      end
    )
  end

  defp reduce_create_participant(:error, _participant_data, multi) do
    multi
  end

  defp reduce_set_opponent_participant(participant_data, multi) do
    Multi.update(
      multi,
      {:update_participant, participant_data["puuid"]},
      fn changes ->
        with {:ok, participant_key} <- fetch_participant_key(participant_data),
             {:ok, opponent_participant_key} <- fetch_opponent_participant_key(participant_data),
             {:ok, participant} <- Map.fetch(changes, {:participant, participant_key}),
             {:ok, opponent_participant} <-
               Map.fetch(changes, {:participant, opponent_participant_key}) do
          change_participant_opponent(participant, opponent_participant.id)
        else
          _ ->
            # There is a missing data in this participant we put a changeset with
            # an error to make the multi fail
            Ecto.Changeset.add_error(%Ecto.Changeset{}, :participant, "not_found")
        end
      end
    )
  end

  @doc """
  Helpers to to convert match_data to game changeset.
  """
  def change_game(match_data) do
    game_attrs = %{
      creation_int: get_in(match_data, ["info", "gameCreation"]),
      duration: get_in(match_data, ["info", "gameDuration"]),
      platform_id: get_in(match_data, ["info", "platformId"]) |> String.downcase(),
      riot_id: get_in(match_data, ["metadata", "matchId"]),
      version: get_in(match_data, ["info", "gameVersion"]),
      winner: get_winner_team(match_data)
    }

    Game.changeset(%Game{}, game_attrs)
  end

  defp get_winner_team(match_data) do
    match_data
    |> get_in(~w(info teams)s)
    |> Enum.filter(fn team -> team["win"] end)
    |> List.first()
    |> Kernel.||(%{})
    |> Map.get("teamId")
  end

  @doc """
  Helpers to to convert game, participant_data, summoner into a participant changeset.
  """
  def change_participant(game, participant_data, summoner) do
    participant_attrs = %{
      kills: Map.get(participant_data, "kills"),
      deaths: Map.get(participant_data, "deaths"),
      assists: Map.get(participant_data, "assists"),
      champion_id: Map.get(participant_data, "championId"),
      gold_earned: Map.get(participant_data, "goldEarned"),
      summoners: Map.take(participant_data, ["summoner1Id", "summoner2Id"]) |> Map.values(),
      items: Map.take(participant_data, for(n <- 0..6, do: "item#{n}")) |> Map.values(),
      team_position: Map.get(participant_data, "teamPosition"),
      game_id: game.id,
      summoner_id: summoner.id,
      team_id: Map.get(participant_data, "teamId"),
      win: Map.get(participant_data, "win")
    }

    Participant.changeset(%Participant{}, participant_attrs)
  end

  @doc """
  Change participant opponent.
  """
  def change_participant_opponent(participant, opponent_participant_id) do
    Participant.changeset(participant, %{opponent_participant_id: opponent_participant_id})
  end
end
