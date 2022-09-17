defmodule ProbuildEx.Games do
  @moduledoc """
  The context module to manage the creation / updates of schemas.
  """

  import Ecto.Query

  alias ProbuildEx.Repo

  alias ProbuildEx.Games.{
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
end
