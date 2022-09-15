defmodule ProbuildEx.RiotApi do
  @moduledoc """
  A thin wrapper around the rest riot api for the endpoint we are interested in.
  """

  require Logger

  @ranked_solo_game 420

  @regions_routing_map %{
    "americas" => ["na1", "br1", "la1", "la2"],
    "asia" => ["kr", "jp1"],
    "europe" => ["eun1", "euw1", "tr1", "ru"],
    "sea" => ["oc1"]
  }

  @regions Map.keys(@regions_routing_map)

  @platform_ids_routing_map %{
    "br1" => "americas",
    "jp1" => "asia",
    "kr" => "asia",
    "la1" => "americas",
    "la2" => "americas",
    "na1" => "americas",
    "oc1" => "sea",
    "ru" => "europe",
    "tr1" => "europe",
    "eun1" => "europe",
    "euw1" => "europe"
  }

  @platform_ids Map.keys(@platform_ids_routing_map)

  # Get token from config.
  defp token do
    Application.get_env(:probuild_ex, __MODULE__)[:token]
  end

  @doc """
  Create a tesla client.
  """
  def new(region, option \\ nil) do
    middlewares = [
      # this will make the request retry automatically when we hit the rate limit
      # and get a 429 status or the riot api return a 500 status
      {Tesla.Middleware.Retry,
       [
         delay: 10_000,
         max_retries: 20,
         max_delay: 60_000,
         should_retry: fn
           {:ok, %{status: status}} when status in [429, 503] -> true
           {:ok, _} -> false
           {:error, _} -> true
         end
       ]},
      # pass the riot token in header
      {Tesla.Middleware.Headers, [{"X-Riot-Token", token()}]},
      # set the BaseUrl depending what region endpoint we want to call
      {Tesla.Middleware.BaseUrl, url(region, option)},
      # parse the JSON response automatically
      Tesla.Middleware.JSON,
      # Logger
      Tesla.Middleware.Logger
    ]

    Tesla.client(middlewares)
  end

  # Depending on the endpoint we need to put a region or a platform_id
  # in some case we want the region who match the platform_id
  def url(region_or_platform_id, option)

  def url(region, nil) when region in @regions do
    "https://#{region}.api.riotgames.com"
  end

  def url(platform_id, nil) when platform_id in @platform_ids do
    "https://#{platform_id}.api.riotgames.com"
  end

  def url(platform_id, :convert_platform_to_region_id) when platform_id in @platform_ids do
    region = Map.get(@platform_ids_routing_map, platform_id)
    url(region, nil)
  end

  @doc """
  Given a tesla client a puuid and optionnaly a start return a list of
  ranked_solo_game match ids.
  ## Example
    iex> RiotApi.list_matches(client, "8tjefad_ZLY2X8UbmwYlR1PBtaRgJBxcOcvFZ8tMy6f4bw56fMaIvLoqA87DK3yzqihZs7L-VQCdBw")
    ["EUW1_5794787018", "EUW1_5786706582", "EUW1_5777719214", "EUW1_5723851410",
     "EUW1_5630385359", "EUW1_5630305794", ...]
  """
  def list_matches(client, puuid, start \\ 0) do
    path = "/lol/match/v5/matches/by-puuid/#{puuid}/ids?"
    query = URI.encode_query(start: start, count: 100, queue: @ranked_solo_game)

    %{body: match_ids, status: 200} = Tesla.get!(client, path <> query)
    match_ids
  end

  @doc """
  Given a tesla client and a match_id return a match_data.
  ## Example
    iex> RiotApi.fetch_match(client, "EUW1_5794787018")
    {:ok,
      %{
        "info" => ...,
        "metadata" => ...
      }
    }
  """
  def fetch_match(client, match_id) do
    path = "/lol/match/v5/matches/#{match_id}"

    case Tesla.get!(client, path) do
      %{status: 200, body: match_data} ->
        {:ok, match_data}

      %{status: 404} ->
        {:error, :not_found}

      other ->
        Logger.error(other)
        {:error, :unknow_error}
    end
  end

  @doc """
  Given a tesla client and a summoner_name get summoner_data
  ## Example
    iex> RiotApi.fetch_summoner_by_name(client, "godindatzotak")
    {:ok,
     %{
       "accountId" => "5H_Q0vPz0WFtt1mzOKicsavLEuYjLSDG-gNsKVBO4FjQBg",
       "id" => "2cNWTjUhUDNQlS-WEB1mIj6bePcdTxz17Gecw4RDQ90H4qA",
       "name" => "GodinDatZotak",
       "profileIconId" => 7,
       "puuid" => "8tjefad_ZLY2X8UbmwYlR1PBtaRgJBxcOcvFZ8tMy6f4bw56fMaIvLoqA87DK3yzqihZs7L-VQCdBw",
       "revisionDate" => 1660161403000,
       "summonerLevel" => 112
     }}
  """
  def fetch_summoner_by_name(client, summoner_name) do
    path = "/lol/summoner/v4/summoners/by-name/#{summoner_name}"

    case Tesla.get!(client, path) do
      %{status: 200, body: summoner_data} ->
        {:ok, summoner_data}

      %{status: 404} ->
        {:error, :not_found}

      other ->
        Logger.error(other)
        {:error, :unknow_error}
    end
  end

  @doc """
  Given a tesla client and a puuid get summoner_data
  ## Example
    iex> RiotApi.fetch_summoner_by_puuid(client, "8tjefad_ZLY2X8UbmwYlR1PBtaRgJBxcOcvFZ8tMy6f4bw56fMaIvLoqA87DK3yzqihZs7L-VQCdBw")
    {:ok,
     %{
       "accountId" => "5H_Q0vPz0WFtt1mzOKicsavLEuYjLSDG-gNsKVBO4FjQBg",
       "id" => "2cNWTjUhUDNQlS-WEB1mIj6bePcdTxz17Gecw4RDQ90H4qA",
       "name" => "GodinDatZotak",
       "profileIconId" => 7,
       "puuid" => "8tjefad_ZLY2X8UbmwYlR1PBtaRgJBxcOcvFZ8tMy6f4bw56fMaIvLoqA87DK3yzqihZs7L-VQCdBw",
       "revisionDate" => 1660161403000,
       "summonerLevel" => 112
     }}
  """
  def fetch_summoner_by_puuid(client, puuid) do
    path = "/lol/summoner/v4/summoners/by-puuid/#{puuid}"

    case Tesla.get!(client, path) do
      %{status: 200, body: summoner_data} ->
        {:ok, summoner_data}

      %{status: 404} ->
        {:error, :not_found}

      other ->
        Logger.error(other)
        {:error, :unknow_error}
    end
  end
end
