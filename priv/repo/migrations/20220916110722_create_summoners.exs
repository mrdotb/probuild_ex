defmodule ProbuildEx.Repo.Migrations.CreateSummoners do
  use Ecto.Migration

  def change do
    create table(:summoners) do
      add :name, :text, null: false
      add :puuid, :text, null: false
      add :platform_id, :string, null: false
      # Note the pro_id can be null
      add :pro_id, references(:pros, on_delete: :delete_all), null: true

      timestamps()
    end

    create unique_index(:summoners, [:puuid, :platform_id])
    create index(:summoners, [:pro_id])
  end
end
