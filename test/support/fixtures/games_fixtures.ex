defmodule ProbuildEx.GamesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Games` context.
  """

  @doc """
  Generate a unique team name.
  """
  def unique_team_name, do: "team name #{System.unique_integer([:positive])}"

  @doc """
  Generate a team.
  """
  def team_fixture(name \\ unique_team_name()) do
    {:ok, team} = ProbuildEx.Games.fetch_or_create_team(name)

    team
  end

  @doc """
  Generate a unique pro name.
  """
  def unique_pro_name, do: "pro name #{System.unique_integer([:positive])}"

  @doc """
  Generate a pro.
  """
  def pro_fixture(name \\ unique_pro_name(), team \\ team_fixture()) do
    {:ok, pro} = ProbuildEx.Games.fetch_or_create_pro(name, team.id)

    pro
  end

  @doc """
  Generate a unique attrs for summoner.
  """
  def unique_summoner_attrs(attrs \\ %{}) do
    summoner_name = "summoner name #{System.unique_integer([:positive])}"
    puuid = Ecto.UUID.generate()

    Enum.into(
      attrs,
      %{
        "name" => summoner_name,
        "platform_id" => "euw1",
        "puuid" => puuid
      }
    )
  end

  @doc """
  Generate a summoner.
  """
  def summoner_fixture(attrs \\ %{}, pro \\ pro_fixture()) do
    attrs =
      attrs
      |> Enum.into(%{"pro_id" => pro.id})
      |> unique_summoner_attrs()

    {:ok, summoner} = ProbuildEx.Games.create_summoner(attrs)
    summoner
  end
end
