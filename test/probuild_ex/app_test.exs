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

  describe "game" do
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

    test "paginate_pro_participants/1 should return participant matching the query" do
      # This game off weiwei is on :kr and his position is :TOP and play yone
      create_weiwei_game()

      %{entries: [_]} = App.paginate_pro_participants(%{search: "weiwei"})
      %{entries: [_]} = App.paginate_pro_participants(%{search: "yone"})
      %{entries: [_]} = App.paginate_pro_participants(%{platform_id: :kr})
      %{entries: [_]} = App.paginate_pro_participants(%{team_position: :TOP})

      %{entries: []} = App.paginate_pro_participants(%{search: "faker"})
      %{entries: []} = App.paginate_pro_participants(%{platform_id: :euw1})
      %{entries: []} = App.paginate_pro_participants(%{team_position: :MIDDLE})
    end

    test "fetch_game/1 should return a game" do
      {:ok, multi} = create_weiwei_game()
      assert {:ok, _game} = App.fetch_game(multi.game.id)
    end

    test "fetch_game/1 should return an error" do
      assert {:error, :not_found} = App.fetch_game(1337)
    end
  end
end
