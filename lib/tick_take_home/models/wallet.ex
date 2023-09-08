defmodule TickTakeHome.Models.Wallets do
  use Ecto.Schema
  #import Ecto.Changeset

  schema "wallets" do
    has_many :users, TickTakeHome.Models.Users, foreign_key: :wallet_id

    timestamps()
  end

end
