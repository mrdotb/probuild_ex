defmodule ProbuildExWeb.GameLive.Index do
  use ProbuildExWeb, :live_view

  alias ProbuildEx.App

  @impl true
  def mount(_params, _session, socket) do
    socket = assign(socket, participants: App.list_pro_participant_summoner([]))
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
  end
end
