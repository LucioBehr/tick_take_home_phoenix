defmodule TickTakeHome.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :wallet_id, references(:wallets, on_delete: :delete_all)
      timestamps()
    end
  end
end
