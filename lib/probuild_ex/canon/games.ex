defmodule ProbuildEx.Canon.Games do
  @moduledoc """
  The Games Canon pipeline.

  All the call to RiotApi happens here.

  Step:
  - Query our database for pro summoner of the selected platform_id.
  - Request RiotApi for the match_ids of the pro summoner.
  - Filter match_ids that already exist in our database.
  - Request RiotApi for the pro summoner match_ids.
  - Request RiotApi for the data of the match_id.
  - Request our database or RiotApi for the summoners.
  - Create Game with participants and summoners in our database.
  """

  alias ProbuildEx.{
    Games,
    RiotApi
  }

  require Logger

  def run(platform_id \\ "euw1") do
    region_client = RiotApi.new(platform_id, :convert_platform_to_region_id)
    platform_client = RiotApi.new(platform_id)

    platform_id
    |> Games.list_pro_summoners()
    |> Stream.map(fn summoner ->
      RiotApi.list_matches(region_client, summoner.puuid)
    end)
    |> Stream.flat_map(&Games.reject_existing_games/1)
    |> Stream.map(fn riot_id ->
      with {:ok, match_data} <- RiotApi.fetch_match(region_client, riot_id),
           {:ok, summoners_list} <- fetch_summoners(platform_id, platform_client, match_data) do
        {match_data, summoners_list}
      end
    end)
    |> Stream.reject(fn
      {:error, _} -> true
      {_match_data, _summoners_list} -> false
    end)
    |> Stream.map(fn {match_data, summoners_list} ->
      platform_id
      |> Games.create_game_complete(match_data, summoners_list)
      |> log_failed_transaction()
    end)
    |> Stream.run()
  end

  defp fetch_summoners(platform_id, platform_client, match_data) do
    puuids_list = get_in(match_data, ["metadata", "participants"])

    summoners_list =
      Enum.reduce_while(puuids_list, [], fn puuid, acc ->
        with {:error, :not_found} <- Games.fetch_summoner(puuid: puuid, platform_id: platform_id),
             {:ok, summoner_data} <- RiotApi.fetch_summoner_by_puuid(platform_client, puuid) do
          {:cont, [summoner_data | acc]}
        else
          {:ok, summoner} ->
            {:cont, [summoner | acc]}

          # We did not find the summoner in the RiotApi stop fetching summoners return empty list
          {:error, :not_found} ->
            {:halt, []}
        end
      end)

    case summoners_list do
      [] ->
        {:error, :summoner_puuid_not_found}

      summoners_list ->
        {:ok, summoners_list}
    end
  end

  defp log_failed_transaction(result) do
    case result do
      {:ok, _} ->
        :ok

      # Game with missing attributes version or winner
      {:error, :game, %{errors: _}, _any} ->
        :ok

      # Game with summoners missing their team_position
      {:error, {:participant, _}, %{errors: [{:team_position, _}]}, _any} ->
        :ok

      {:error, any} ->
        Logger.error(any)

      {:error, multi_name, changeset, multi} ->
        Logger.error("""
          multi_name:
          #{inspect(multi_name)}
          changeset:
          #{inspect(changeset)}
          multi:
          #{inspect(multi)}
        """)
    end
  end
end
