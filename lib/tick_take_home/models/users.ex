defmodule TickTakeHome.Models.Users do
  use Ecto.Schema
  import Ecto.Changeset


  schema "users" do
    belongs_to :wallet, TickTakeHome.Models.Wallets

    has_many :balances, TickTakeHome.Models.Balances, foreign_key: :user_id
    #has_many :asset, TickTakeHome.Models.Assets

    timestamps()

  end

  def changeset(user, params \\ %{}) do
    user
    |> cast(params, [:id, :wallet_id])
    |> validate_required([:id, :wallet_id])
  end
end
