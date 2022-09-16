defmodule ProbuildEx.Games.Game do
  use Ecto.Schema
  import Ecto.Changeset

  alias ProbuildEx.Games.Participant

  schema "games" do
    field :creation, :utc_datetime
    field :duration, :integer

    field :platform_id, Ecto.Enum,
      values: [:br1, :eun1, :euw1, :jp1, :kr, :la1, :la2, :na1, :oc1, :ru, :tr1]

    field :riot_id, :string
    field :version, :string
    field :winner, :integer

    has_many :participants, Participant

    timestamps()
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [:creation, :duration, :platform_id, :riot_id, :version, :winner])
    |> validate_required([:creation, :duration, :platform_id, :riot_id, :version, :winner])
    |> unique_constraint(:riot_id)
  end
end
