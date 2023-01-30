defmodule ProbuildEx.Repo.Migrations.CreateGamesCreationDescIndex do
  use Ecto.Migration

  def change do
    create index(:games, ["creation DESC"])
  end
end
