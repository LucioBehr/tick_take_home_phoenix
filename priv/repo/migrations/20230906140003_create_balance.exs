defmodule TickTakeHome.Repo.Migrations.CreateBalance do
  use Ecto.Migration

  def change do
    create table(:balances) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :asset_id, references(:assets, type: :string, on_delete: :nothing)
      add :available, :float, null: false, default: 0.0
      add :frozen, :float, null: false, default: 0.0
      timestamps()
    end
  end
end
