defmodule ProbuildEx.Games.Pro do
  use Ecto.Schema
  import Ecto.Changeset

  alias ProbuildEx.Games.Team

  schema "pros" do
    field :name, :string
    belongs_to :team, Team

    timestamps()
  end

  @doc false
  def changeset(pro, attrs) do
    pro
    |> cast(attrs, [:name, :team_id])
    |> validate_required([:name, :team_id])
    |> unique_constraint(:name)
    |> foreign_key_constraint(:team_id)
  end
end
