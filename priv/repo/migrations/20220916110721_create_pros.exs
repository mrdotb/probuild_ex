defmodule ProbuildEx.Repo.Migrations.CreatePros do
  use Ecto.Migration

  def change do
    create table(:pros) do
      add :name, :text, null: false
      add :team_id, references(:teams, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:pros, [:name])
    create index(:pros, [:team_id])
  end
end
