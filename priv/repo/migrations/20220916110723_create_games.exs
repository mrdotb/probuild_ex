defmodule ProbuildEx.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games) do
      add :creation, :utc_datetime, null: false
      add :duration, :integer, null: false
      add :platform_id, :string, null: false
      add :riot_id, :text, null: false
      add :version, :text, null: false
      add :winner, :integer, null: false

      timestamps()
    end

    create unique_index(:games, [:riot_id])
  end
end
