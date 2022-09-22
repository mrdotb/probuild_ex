defmodule ProbuildExWeb.GameLive.GridElementComponent do
  @moduledoc false

  use Phoenix.Component

  import ProbuildExWeb.GameLive.DdragonComponent

  def time_ago(assigns) do
    ~H"""
    <div class="grid-area-creation flex md:justify-center items-center">
      <time id={["time", to_string(@participant_id)]} phx-hook="TimeAgo" datetime={@game_creation}></time>
    </div>
    """
  end

  def pro_name(assigns) do
    ~H"""
    <div class="grid-area-player flex items-center">
      <!-- Heroicon name: user-circle -->
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-8 h-8">
        <path fill-rule="evenodd" d="M18.685 19.097A9.723 9.723 0 0021.75 12c0-5.385-4.365-9.75-9.75-9.75S2.25 6.615 2.25 12a9.723 9.723 0 003.065 7.097A9.716 9.716 0 0012 21.75a9.716 9.716 0 006.685-2.653zm-12.54-1.285A7.486 7.486 0 0112 15a7.486 7.486 0 015.855 2.812A8.224 8.224 0 0112 20.25a8.224 8.224 0 01-5.855-2.438zM15.75 9a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0z" clip-rule="evenodd" />
      </svg>
      <span class="flex-1 ml-1 text-ellipsis overflow-hidden">
        <%= @pro_name %>
      </span>
    </div>
    """
  end

  def versus(assigns) do
    ~H"""
    <div class="grid-area-versus flex justify-center items-center space-x-1">
      <.champion game_version={@game_version} champion_id={@champion_id} />
      <span>vs</span>
      <.champion game_version={@game_version} champion_id={@opponent_champion_id} />
    </div>
    """
  end

  def kda(assigns) do
    ~H"""
    <div class="grid-area-kda flex justify-center items-center">
      <span class="font-medium">
        <%= @kills %>
      </span>
      /
      <span class="font-medium text-red-500">
        <%= @deaths %>
      </span>
      /
      <span class="font-medium">
       <%= @assists %>
      </span>
    </div>
    """
  end

  def summoners(assigns) do
    ~H"""
    <div class="grid-area-summoners flex justify-center items-center space-x-1">
      <%= for summoner_key <- @summoners do %>
        <.summoner game_version={@game_version} summoner_key={summoner_key} />
      <% end %>
    </div>
    """
  end

  def items(assigns) do
    ~H"""
    <div class="grid-area-build flex justify-center items-center space-x-1">
      <%= for item_key <- @items do %>
        <.item game_version={@game_version} item_key={item_key} />
      <% end %>
    </div>
    """
  end

  def ellipsis(assigns) do
    ~H"""
    <div class="grid-area-ellipsis hidden md:flex flex-1 justify-center items-center">
      <!-- Heroicon name: ellipsis-vertical -->
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-6 h-6">
        <path fill-rule="evenodd" d="M4.5 12a1.5 1.5 0 113 0 1.5 1.5 0 01-3 0zm6 0a1.5 1.5 0 113 0 1.5 1.5 0 01-3 0zm6 0a1.5 1.5 0 113 0 1.5 1.5 0 01-3 0z" clip-rule="evenodd" />
      </svg>
    </div>
    """
  end

  def champion_block(assigns) do
    ~H"""
    <div class="grid-area-champion">
      <.champion game_version={@game_version} champion_id={@champion_id} />
    </div>
    """
  end

  def summoner_champion(assigns) do
    ~H"""
    <div class="grid-area-summoner-name flex items-center">
      <.champion game_version={@game_version} champion_id={@champion_id} />
      <span class="ml-1 text-ellipsis overflow-hidden whitespace-nowrap">
        <%= @summoner_name %>
      </span>
    </div>
    """
  end

  def gold_earned(assigns) do
    ~H"""
    <div class="grid-area-gold flex justify-center items-center text-yellow-600">
      <%= @gold_earned %>
    </div>
    """
  end
end
