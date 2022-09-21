defmodule ProbuildEx.Ddragon.Cache do
  @moduledoc """
  Cache the call of the ddragon api in :ets and provide singular ressource
  fetch.
  """
  use GenServer, restart: :transient

  alias ProbuildEx.Ddragon.Api

  ## Client

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def fetch_champion_img(key) do
    GenServer.call(__MODULE__, {:fetch_champion_img, key})
  end

  def fetch_champions_search_map do
    GenServer.call(__MODULE__, :fetch_champions_search_map)
  end

  def fetch_summoner_img(key) do
    GenServer.call(__MODULE__, {:fetch_summoner_img, key})
  end

  ## Server

  def init(_) do
    opts = [:set, :named_table, :public, read_concurrency: true]
    :ets.new(:champions, opts)
    :ets.new(:summoners, opts)

    request_and_cache_champions()
    request_and_cache_summoners()

    {:ok, [], {:continue, :warmup}}
  end

  def handle_continue(:warmup, state) do
    request_and_cache_champions()
    request_and_cache_summoners()

    {:noreply, state}
  end

  def handle_call({:fetch_champion_img, champion_key}, _from, state) do
    response =
      case :ets.lookup(:champions, {:img, champion_key}) do
        [{_, champion_img}] ->
          {:ok, champion_img}

        [] ->
          {:error, :not_found}
      end

    {:reply, response, state}
  end

  def handle_call(:fetch_champions_search_map, _from, state) do
    response =
      case :ets.lookup(:champions, :search_map) do
        [{_, champions_map}] ->
          {:ok, champions_map}

        [] ->
          {:error, :not_found}
      end

    {:reply, response, state}
  end

  def handle_call({:fetch_summoner_img, summoner_key}, _from, state) do
    response =
      case :ets.lookup(:summoners, {:img, summoner_key}) do
        [{_, summoner_img}] ->
          {:ok, summoner_img}

        [] ->
          {:error, :not_found}
      end

    {:reply, response, state}
  end

  defp request_and_cache_champions do
    with {:ok, %{body: versions}} <- Api.fetch_versions(),
         last_game_version <- List.first(versions),
         {:ok, %{body: champions_response}} <- Api.fetch_champions(last_game_version) do
      champions_search_map = create_champions_search_map(champions_response)
      champions_img_map = create_champions_img_map(champions_response)

      :ets.insert(:champions, {:search_map, champions_search_map})

      Enum.each(champions_img_map, fn {key, img} ->
        :ets.insert(:champions, {{:img, key}, img})
      end)
    end
  end

  defp request_and_cache_summoners do
    with {:ok, %{body: versions}} <- Api.fetch_versions(),
         last_game_version <- List.first(versions),
         {:ok, %{body: summoners_response}} <- Api.fetch_summoners(last_game_version) do
      summoners_img_map = create_summoners_img_map(summoners_response)

      Enum.each(summoners_img_map, fn {key, img} ->
        :ets.insert(:summoners, {{:img, key}, img})
      end)
    end
  end

  defp create_champions_img_map(champions_response) do
    champions_response
    |> Map.get("data")
    |> Enum.map(fn {_champion_id, data} ->
      key = String.to_integer(data["key"])
      value = data["image"]["full"]
      {key, value}
    end)
    |> Map.new()
  end

  defp create_champions_search_map(champions_response) do
    champions_response
    |> Map.get("data")
    |> Enum.map(fn {_champion_id, data} ->
      key = String.downcase(data["name"])
      value = String.to_integer(data["key"])
      {key, value}
    end)
    |> Map.new()
  end

  defp create_summoners_img_map(summoners_response) do
    summoners_response
    |> Map.get("data")
    |> Enum.map(fn {_summoner_id, data} ->
      key = String.to_integer(data["key"])
      value = data["image"]["full"]
      {key, value}
    end)
    |> Map.new()
  end
end
