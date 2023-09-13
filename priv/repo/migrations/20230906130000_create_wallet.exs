defmodule TickTakeHome.Repo.Migrations.CreateWallet do
  use Ecto.Migration

  def change do
    create table(:wallets) do
      timestamps()
    end
  end
end
