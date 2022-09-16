defmodule ProbuildEx.Games.Participant do
  use Ecto.Schema
  import Ecto.Changeset

  alias ProbuildEx.Games.{
    Game,
    Participant,
    Summoner
  }

  schema "participants" do
    field :assists, :integer
    field :champion_id, :integer
    field :deaths, :integer
    field :gold_earned, :integer
    field :items, {:array, :integer}
    field :kills, :integer
    field :summoners, {:array, :integer}
    field :team_id, :integer
    field :team_position, Ecto.Enum, values: [:UTILITY, :TOP, :JUNGLE, :MIDDLE, :BOTTOM]
    field :win, :boolean, default: false

    belongs_to :game, Game
    belongs_to :summoner, Summoner
    belongs_to :opponent_participant, Participant

    timestamps()
  end

  @doc false
  def changeset(participant, attrs) do
    participant
    |> cast(attrs, [
      :assists,
      :champion_id,
      :deaths,
      :gold_earned,
      :items,
      :kills,
      :summoners,
      :team_position,
      :team_id,
      :win,
      :game_id,
      :summoner_id,
      :opponent_participant_id
    ])
    |> validate_required([
      :assists,
      :champion_id,
      :deaths,
      :gold_earned,
      :items,
      :kills,
      :summoners,
      :team_position,
      :team_id,
      :win,
      :game_id,
      :summoner_id
    ])
    |> foreign_key_constraint(:game_id)
    |> foreign_key_constraint(:summoner_id)
    |> foreign_key_constraint(:opponent_participant_id)
  end
end
