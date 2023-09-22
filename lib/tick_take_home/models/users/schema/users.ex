defmodule TickTakeHome.Models.Users.Schema.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    belongs_to :wallet, TickTakeHome.Models.Wallet.Schema.Wallet, foreign_key: :wallet_id

    has_many :balances, TickTakeHome.Models.Balances.Schema.Balance, foreign_key: :user_id
    # has_many :asset, TickTakeHome.Models.Assets.Schema.Asset

    timestamps()
  end

  def changeset(user, params \\ %{}) do
    user
    |> cast(params, [:id, :wallet_id])
    |> validate_required([:wallet_id])
    |> foreign_key_constraint(:wallet_id, name: "users_wallet_id_fkey")
  end
end
