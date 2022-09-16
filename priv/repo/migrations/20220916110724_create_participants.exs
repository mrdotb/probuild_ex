defmodule ProbuildEx.Repo.Migrations.CreateParticipants do
  use Ecto.Migration

  def change do
    create table(:participants) do
      add :assists, :integer, null: false
      add :champion_id, :integer, null: false
      add :deaths, :integer, null: false
      add :gold_earned, :integer, null: false
      add :items, {:array, :integer}, null: false
      add :kills, :integer, null: false
      add :summoners, {:array, :integer}, null: false
      add :team_position, :string, null: false
      add :team_id, :integer, null: false
      add :win, :boolean, null: false
      add :game_id, references(:games, on_delete: :delete_all), null: false
      add :summoner_id, references(:summoners, on_delete: :delete_all), null: false
      # Note the opponent_participant can be null
      add :opponent_participant_id, references(:participants, on_delete: :delete_all), null: true

      timestamps()
    end

    create index(:participants, [:game_id])
    create index(:participants, [:summoner_id])
    create index(:participants, [:opponent_participant_id])
  end
end
