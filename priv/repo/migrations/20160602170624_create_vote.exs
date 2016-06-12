defmodule HelloPhoenix.Repo.Migrations.CreateVote do
  use Ecto.Migration

  def change do
    create table(:votes) do
      add :nickname, :string
      add :poll_id, references(:polls, on_delete: :nothing)
      add :candidate_id, references(:candidates, on_delete: :nothing)

      timestamps
    end
    create index(:votes, [:poll_id])
    create index(:votes, [:candidate_id])

  end
end
