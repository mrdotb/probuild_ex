defmodule ProbuildEx.Canon.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    config = Application.get_env(:probuild_ex, :canon)
    games = config[:games]
    pros = config[:pros]

    canon_games =
      for platform_id <- games[:platform_ids] do
        Supervisor.child_spec(
          {ProbuildEx.Canon.Cron, {games[:delay], {ProbuildEx.Canon.Games, :run, [platform_id]}}},
          id: String.to_atom("game_" <> platform_id)
        )
      end

    canon_pros =
      for platform_id <- pros[:platform_ids] do
        Supervisor.child_spec(
          {ProbuildEx.Canon.Cron, {pros[:delay], {ProbuildEx.Canon.Pros, :run, [platform_id]}}},
          id: String.to_atom("pro_" <> platform_id)
        )
      end

    children = canon_games ++ canon_pros

    Supervisor.init(children, strategy: :one_for_one)
  end
end
