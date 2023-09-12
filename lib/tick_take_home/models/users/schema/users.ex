defmodule TickTakeHome.Models.Users.Schema.User do
  use Ecto.Schema
  import Ecto.Changeset


  schema "users" do
    belongs_to :wallet, TickTakeHome.Models.Wallets.Schema.Wallet

    has_many :balances, TickTakeHome.Models.Balances.Schema.Balance, foreign_key: :user_id
    #has_many :asset, TickTakeHome.Models.Assets.Schema.Asset

    timestamps()

  end

  def changeset(user, params \\ %{}) do
    user
    |> cast(params, [:id, :wallet_id])
    |> validate_required([:wallet_id])
  end
end
