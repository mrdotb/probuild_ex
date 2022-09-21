defmodule ProbuildExWeb.GameLive.Index do
  use ProbuildExWeb, :live_view

  alias ProbuildEx.App
  alias ProbuildEx.Ddragon

  @defaults %{
    page_title: "Listing games",
    update: "append",
    changeset: App.Search.changeset(),
    search: %App.Search{},
    page: %Scrivener.Page{},
    participants: [],
    loading?: true,
    load_more?: false
  }

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, @defaults), temporary_assigns: [participants: []]}
  end

  @impl true
  def handle_params(params, _url, socket) do
    # Avoid double request learn more on the article below
    # https://kobrakai.de/kolumne/liveview-double-mount/
    socket =
      if connected?(socket) do
        apply_action(socket, socket.assigns.live_action, params)
      else
        socket
      end

    {:noreply, socket}
  end

  defp apply_action(socket, :index, params) do
    changeset = App.Search.changeset(socket.assigns.search, params)

    case App.Search.validate(changeset) do
      {:ok, search} ->
        opts = App.Search.to_map(search)
        # Don't block the apply_action, execute the slow request in handle_info
        send(self(), {:query_pro_participants, opts})

        assign(
          socket,
          changeset: changeset,
          search: search,
          loading?: true
        )

      {:error, _changest} ->
        socket
    end
  end

  @impl true
  def handle_event(
        "filter",
        %{"search" => %{"platform_id" => platform_id, "search" => search}},
        socket
      ) do
    changeset =
      App.Search.changeset(socket.assigns.search, %{
        "platform_id" => platform_id,
        "search" => search
      })

    socket =
      case App.Search.validate(changeset) do
        {:ok, search} ->
          socket
          |> assign(changeset: changeset, search: search)
          |> push_patch_index()

        {:error, _changest} ->
          socket
      end

    {:noreply, socket}
  end

  def handle_event("team_position", %{"position" => position}, socket) do
    changeset = App.Search.changeset(socket.assigns.search, %{"team_position" => position})

    socket =
      case App.Search.validate(changeset) do
        {:ok, search} ->
          socket
          |> assign(changeset: changeset, search: search)
          |> push_patch_index()

        {:error, _changest} ->
          socket
      end

    {:noreply, socket}
  end

  def handle_event("load-more", _params, socket) do
    page = socket.assigns.page

    socket =
      if page.page_number < page.total_pages do
        opts = App.Search.to_map(socket.assigns.search)
        # Don't block the load-more event, execute the slow request in handle_info
        send(self(), {:query_pro_participants, opts, page.page_number + 1})
        assign(socket, load_more?: true)
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:query_pro_participants, opts}, socket) do
    page = App.paginate_pro_participants(opts)

    socket =
      assign(
        socket,
        update: "replace",
        page: page,
        participants: page.entries,
        loading?: false
      )

    {:noreply, socket}
  end

  def handle_info({:query_pro_participants, opts, page_number}, socket) do
    page = App.paginate_pro_participants(opts, page_number)

    socket =
      assign(
        socket,
        update: "append",
        page: page,
        participants: page.entries,
        load_more?: false
      )

    {:noreply, socket}
  end

  defp push_patch_index(socket) do
    params = App.Search.to_map(socket.assigns.search)
    push_patch(socket, to: Routes.game_index_path(socket, :index, params))
  end
end
