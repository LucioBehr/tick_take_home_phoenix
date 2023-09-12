defmodule TickTakeHome.Models.Balances.Repositories.Database do
  alias TickTakeHome.Models.Balances.Schema.Balance
  alias TickTakeHome.Repo
  import Ecto.Query

  def get_balance(user_id, asset) do
    Repo.one(from b in Balance, where: b.user_id == ^user_id and b.asset_id == ^asset)
  end

  def insert_balance(%{"user_id" => user_id, "asset_id" => asset, "available" => amount}) do
    Repo.insert!(Balance.changeset(%Balance{}, %{"user_id" => user_id, "asset_id" => asset, "available" => amount}))
  end

  def update_balance(%{"user_id" => user_id, "asset" => asset, "amount" => amount, "operation" => operation}) do
    balance = get_balance(user_id, asset)
    case operation do
      :deposit -> Repo.update(Balance.changeset(balance, %{available: balance.available + amount}))
      :withdraw -> Repo.update(Balance.changeset(balance, %{available: balance.available - amount}))
      :freeze -> Repo.update(Balance.changeset(balance, %{frozen: balance.frozen + amount, available: balance.available - amount}))
      :unfreeze -> Repo.update(Balance.changeset(balance, %{frozen: balance.frozen - amount, available: balance.available + amount}))
    end
  end
end
