defmodule ProbuildEx.GamesTest do
  use ExUnit.Case, async: true
  use ProbuildEx.DataCase

  import ProbuildEx.GamesFixtures

  alias ProbuildEx.Games

  describe "team" do
    test "fetch_or_create_team/1 should create team then fetch it" do
      unique_team_name = unique_team_name()
      assert {:ok, created_team} = Games.fetch_or_create_team(unique_team_name)
      assert {:ok, fetched_team} = Games.fetch_or_create_team(unique_team_name)
      assert created_team.id == fetched_team.id
    end
  end

  describe "Pro" do
    test "fetch_or_create_pro/2 should create team then fetch it" do
      team = team_fixture()
      unique_pro_name = unique_pro_name()
      assert {:ok, created_pro} = Games.fetch_or_create_pro(unique_pro_name, team.id)
      assert {:ok, fetched_pro} = Games.fetch_or_create_pro(unique_pro_name, team.id)
      assert created_pro.id == fetched_pro.id
    end
  end

  describe "summoner" do
    test "update_or_create_summoner/1 should create summoner then update it" do
      pro = pro_fixture()
      summoner_attrs = Map.put(unique_summoner_attrs(), "pro_id", pro.id)

      assert {:ok, created_summoner} = Games.update_or_create_summoner(summoner_attrs)

      summoner_attrs = Map.put(summoner_attrs, "name", "faker")
      assert {:ok, updated_summoner} = Games.update_or_create_summoner(summoner_attrs)

      assert created_summoner.id == updated_summoner.id
      assert updated_summoner.name == "faker"
    end

    test "fetch_summoner/1 opts" do
      summoner_fixture(%{"name" => "faker"})
      assert {:ok, _} = Games.fetch_summoner(name: "faker")

      summoner_fixture(%{"puuid" => "123", "platform_id" => "euw1"})
      assert {:ok, _} = Games.fetch_summoner(puuid: "123", platform_id: "euw1")

      summoner_fixture(%{"pro_id" => nil, "puuid" => "abc"})
      assert {:ok, _} = Games.fetch_summoner(is_pro?: false, puuid: "abc")

      summoner_fixture(%{"puuid" => "abcd"})
      assert {:ok, _} = Games.fetch_summoner(is_pro?: true, puuid: "abcd")

      assert {:error, :not_found} = Games.fetch_summoner(puuid: "1234")
    end
  end

  describe "pro transaction" do
    @chovy_ugg %{
      "current_ign" => "Shrimp Shark",
      "current_team" => "Gen.G",
      "league" => "LCK",
      "main_role" => "mid",
      "normalized_name" => "chovy",
      "official_name" => "Chovy",
      "region_id" => "euw1"
    }

    @chovy_summoner_riot %{
      "accountId" => "ei4Gy40LkIa8yXDWgJByZPLwgNBSpTh4GVg7xA1l-RHzq5avJDZq516k",
      "id" => "prjMc2d4I594w7ib9Ws966dDmchDQDxPrY9tckTfrvHuzPCPVIzvoUvapA",
      "name" => "Shrimp Shark",
      "profileIconId" => 29,
      "puuid" => "i91dcy5ekDwcjaHZak-RSmM_NCskwtbH5bLKRwYr_BJvA71QZ14ze61fo4HxkDwJXgk3vfs_bUMqxA",
      "revisionDate" => 1_634_857_524_000,
      "summonerLevel" => 37
    }

    test "create_pro_complete/2 should create team, pro and summoner" do
      assert {:ok, result} = Games.create_pro_complete(@chovy_ugg, @chovy_summoner_riot)
      assert result.team.name == @chovy_ugg["current_team"]
      assert result.pro.name == @chovy_ugg["official_name"]
      assert result.summoner.name == @chovy_summoner_riot["name"]
    end
  end
end
