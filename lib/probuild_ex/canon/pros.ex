defmodule ProbuildEx.Canon.Pros do
  @moduledoc """
  The Pros Canon pipeline.
  Step:
  - Request the UGG pro_list
  - If the pro summoner does not exist in our database
  - Request RiotApi for the data of the pro summoner.
  - Create the pro with team and summoner if they don't exist in our database
  """

  alias ProbuildEx.{
    Games,
    RiotApi,
    UGG
  }

  require Logger

  def run(platform_id \\ "euw1") do
    UGG.pro_list()
    |> Stream.filter(fn ugg_pro ->
      Map.get(ugg_pro, "region_id") == platform_id and not is_nil(ugg_pro["current_ign"])
    end)
    |> Stream.map(fn ugg_pro ->
      name = Map.get(ugg_pro, "current_ign")
      platform_id = Map.get(ugg_pro, "region_id")
      client = RiotApi.new(platform_id)
      opts = [name: name, platform_id: platform_id, is_pro?: true]

      with {:error, :not_found} <- Games.fetch_summoner(opts),
           {:ok, summoner_data} <- RiotApi.fetch_summoner_by_name(client, name) do
        {ugg_pro, summoner_data}
      else
        {:ok, _summoner} -> {:error, :already_exist}
        {:error, :not_found} -> {:error, :not_found}
      end
    end)
    |> Stream.reject(fn
      {:error, _error} -> true
      {_ugg_pro, _summoner_data} -> false
    end)
    |> Stream.map(fn {ugg_pro, summoner_data} ->
      ugg_pro
      |> Games.create_pro_complete(summoner_data)
      |> log_failed_transaction()
    end)
    |> Stream.run()
  end

  defp log_failed_transaction(result) do
    case result do
      {:ok, _} ->
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
