defmodule TickTakeHome.Models.Wallet.Schema.Wallet do
  use Ecto.Schema
  # import Ecto.Changeset

  schema "wallets" do
    has_many :users, TickTakeHome.Models.Users.Schema.User, foreign_key: :wallet_id

    timestamps()
  end
end
