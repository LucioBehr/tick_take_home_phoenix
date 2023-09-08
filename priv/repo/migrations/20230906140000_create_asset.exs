defmodule TickTakeHome.Repo.Migrations.CreateAsset do
  use Ecto.Migration

  def change do
    create table(:assets, primary_key: false) do
      add :id, :string, primary_key: true

      timestamps()
    end
  end
end
