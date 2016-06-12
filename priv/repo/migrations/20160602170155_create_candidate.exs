defmodule HelloPhoenix.Repo.Migrations.CreateCandidate do
  use Ecto.Migration

  def change do
    create table(:candidates) do
      add :name, :string
      add :created_by, :string
      add :poll_id, references(:polls, on_delete: :nothing)

      timestamps
    end
    create index(:candidates, [:poll_id])

  end
end
