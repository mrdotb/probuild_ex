defmodule ProbuildEx.AppTest do
  use ExUnit.Case, async: true
  use ProbuildEx.DataCase

  alias ProbuildEx.{App, Games}
  alias ProbuildEx.GameDataFixtures

  describe "search" do
    test "validate/1 should validate query" do
      query = %{"search" => "faker", "platform_id" => "euw1", "team_position" => "MIDDLE"}
      changeset = App.Search.changeset(%App.Search{}, query)
      assert {:ok, _search} = App.Search.validate(changeset)
    end

    test "validate/1 should ignore extra params" do
      query = %{"bob" => "bob"}
      changeset = App.Search.changeset(%App.Search{}, query)
      assert {:ok, _search} = App.Search.validate(changeset)
    end

    test "validate/1 should error when value not in enum" do
      query = %{"search" => "faker", "platform_id" => "bob", "team_position" => "MIDDLE"}
      changeset = App.Search.changeset(%App.Search{}, query)
      assert {:error, _changeset} = App.Search.validate(changeset)
    end
  end

  describe "list" do
    defp create_weiwei_game do
      data = GameDataFixtures.get()
      weiwei_data = GameDataFixtures.get_weiwei()
      # create weiwei
      {:ok, result} = Games.create_pro_complete(weiwei_data.ugg, weiwei_data.summoner_riot)
      # put weiwei summoner in summoners_list
      summoners_list =
        Enum.map(data.summoners_list, fn summoner ->
          if(summoner["id"] == weiwei_data.summoner_riot["id"],
            do: result.summoner,
            else: summoner
          )
        end)

      Games.create_game_complete(
        data.platform_id,
        data.game_data,
        summoners_list
      )
    end

    test "list_pro_participant_summoner/1 should return participant matching the query" do
      # This game off weiwei is on :kr and his position is :TOP and play yone
      create_weiwei_game()

      [_] = App.list_pro_participant_summoner(%{search: "weiwei"})
      [_] = App.list_pro_participant_summoner(%{search: "yone"})
      [_] = App.list_pro_participant_summoner(%{platform_id: :kr})
      [_] = App.list_pro_participant_summoner(%{team_position: :TOP})

      [] = App.list_pro_participant_summoner(%{search: "faker"})
      [] = App.list_pro_participant_summoner(%{platform_id: :euw1})
      [] = App.list_pro_participant_summoner(%{team_position: :MIDDLE})
    end
  end
end
