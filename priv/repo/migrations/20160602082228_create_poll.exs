defmodule HelloPhoenix.Repo.Migrations.CreatePoll do
  use Ecto.Migration

  def change do
    create table(:polls) do
      add :title, :string
      add :url, :string

      timestamps
    end

  end
end
