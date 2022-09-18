defmodule ProbuildEx.Games.Game do
  use Ecto.Schema
  import Ecto.Changeset

  alias ProbuildEx.Games.Participant

  schema "games" do
    field :creation_int, :integer, virtual: true
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
    |> cast(attrs, [:creation_int, :duration, :platform_id, :riot_id, :version, :winner])
    |> validate_required([:creation_int, :duration, :platform_id, :riot_id, :version, :winner])
    |> clean_version()
    |> cast_creation()
    |> unique_constraint(:riot_id)
  end

  defp clean_version(changeset) do
    case fetch_change(changeset, :version) do
      {:ok, version} ->
        version =
          version
          |> String.split(".")
          |> Enum.take(2)
          |> Enum.join(".")
          |> Kernel.<>(".1")

        put_change(changeset, :version, version)

      :error ->
        changeset
    end
  end

  defp cast_creation(changeset) do
    case fetch_change(changeset, :creation_int) do
      {:ok, creation_int} ->
        creation =
          creation_int
          |> DateTime.from_unix!(:millisecond)
          |> DateTime.truncate(:second)

        put_change(changeset, :creation, creation)

      :error ->
        changeset
    end
  end
end
