defmodule ProbuildExWeb.GameLive.RowComponent do
  use ProbuildExWeb, :live_component

  alias Phoenix.LiveView.JS
  alias ProbuildEx.App

  import ProbuildExWeb.GameLive.GridElementComponent
  import ProbuildExWeb.GameLive.DdragonComponent

  @defaults %{
    load_game?: false,
    game: nil,
    action: nil
  }

  def update(%{action: :query_game}, socket) do
    game_id = socket.assigns.participant.game.id

    socket =
      case App.fetch_game(game_id) do
        {:ok, game} ->
          assign(socket, action: nil, game: game, load_game?: false)

        {:error, :not_found} ->
          socket
      end

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(@defaults)
      |> assign(assigns)

    {:ok, socket}
  end

  def handle_event("load-game", _params, socket) do
    socket =
      cond do
        is_struct(socket.assigns.game) ->
          socket

        is_nil(socket.assigns.game) ->
          send_update(__MODULE__, id: socket.assigns.id, action: :query_game)
          assign(socket, load_game?: true)
      end

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div
        class={[if(@participant.win, do: "border-blue-500", else: "border-red-500"), "border-l-8 w-full max-w-3xl bg-white rounded-lg overflow-hidden shadow"]}>
      <div
        role="button"
        tabIndex="0"
        phx-click={JS.push("load-game") |> JS.toggle(to: "#participant-detail-#{@participant.id}")}
        phx-target={@myself}
        class={[if(@participant.win, do: "border-blue-500", else: "border-red-500"), "hover:bg-gray-100 hover:cursor-pointer px-1 py-2 w-full grid-participants"]}>

          <.time_ago participant_id={@participant.id} game_creation={@participant.game.creation} />

          <.pro_name pro_name={@participant.summoner.pro.name} />

          <.versus game_version={@participant.game.version}
                  champion_id={@participant.champion_id}
                  opponent_champion_id={@participant.opponent_participant.champion_id} />

          <.kda kills={@participant.kills} deaths={@participant.deaths} assists={@participant.assists} />

          <.summoners game_version={@participant.game.version} summoners={@participant.summoners} />

          <.items game_version={@participant.game.version} items={@participant.items} />

          <.ellipsis />

        </div>

        <%= if @load_game? do %>
          <div class="w-full flex justify-center">
            <.spinner load?={@load_game?} />
          </div>
        <% end %>

        <%= if is_struct(@game) do %>
          <.game_detail participant={@participant} game={@game} />
        <% end %>

    </div>
    """
  end

  defp game_detail(assigns) do
    ~H"""
    <div id={"participant-detail-#{@participant.id}"}>
      <div class="game-detail px-2 py-1 space-y-1">
        <%= for {p, player_index} <- Enum.with_index(@game.participants, 1) do %>
          <%= if player_index in [1, 6] do %>
            <div class="px-2 w-full grid-team-participants-header text-xs">
              <div>
                <%= if p.win do %>
                  <span class="text-blue-500 font-medium">Victory</span>
                <% else %>
                  <span class="text-red-500 font-medium">Defeat</span>
                <% end %>
                <%= if(player_index == 1, do: "Blue side") %>
                <%= if(player_index == 6, do: "Red side") %>
              </div>
              <div class="hidden md:flex justify-center">Summoners</div>
              <div class="hidden md:flex justify-center">KDA</div>
              <div class="hidden md:flex justify-center">Gold earned</div>
              <div class="hidden md:flex justify-center">Build</div>
            </div>
          <% end %>
          <div class={[if(p.id == @participant.id, do: "bg-gray-200"), "w-full grid-team-participants py-1 px-2 rounded-md"]}>

            <.summoner_champion
               game_version={@participant.game.version}
               champion_id={p.champion_id}
               summoner_name={p.summoner.name} />

            <.summoners game_version={@participant.game.version} summoners={p.summoners} />

            <.kda kills={p.kills} deaths={p.deaths} assists={p.assists} />

            <.gold_earned gold_earned={p.gold_earned} />

            <.items game_version={@participant.game.version} items={p.items} />

          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
