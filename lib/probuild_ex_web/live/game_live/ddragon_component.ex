defmodule ProbuildExWeb.GameLive.DdragonComponent do
  @moduledoc false

  use Phoenix.Component

  alias ProbuildEx.Ddragon

  def champion(assigns) do
    ~H"""
    <div class="w-8 h-8 rounded-full overflow-hidden bg-gray-900">
      <img src={Ddragon.get_champion_image(@game_version, @champion_id)} class="w-full" />
    </div>
    """
  end

  def summoner(assigns) do
    ~H"""
    <div class="w-8 h-8 rounded-full overflow-hidden bg-gray-900">
      <img src={Ddragon.get_summoner_image(@game_version, @summoner_key)} class="w-full" />
    </div>
    """
  end

  def item(assigns) do
    ~H"""
    <div class="bg-gray-900 w-8 h-8 border border-gray-400">
      <%= if src = Ddragon.get_item_image(@game_version, @item_key) do %>
        <img src={src} class="w-full" />
      <% end %>
    </div>
    """
  end

  def spinner(assigns) do
    ~H"""
    <img class={if not @load?, do: "invisible"} src="https://developer.riotgames.com/static/img/katarina.55a01cf0560a.gif" />
    """
  end
end
