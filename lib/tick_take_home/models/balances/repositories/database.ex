defmodule TickTakeHome.Models.Balances.Repositories.Database do
  alias TickTakeHome.Models.Balances.Schema.Balance
  alias TickTakeHome.Repo
  import Ecto.Query

  def get_balance(user_id, asset) do
    case Repo.one(from b in Balance, where: b.user_id == ^user_id and b.asset_id == ^asset) do
      nil -> {:error, :no_balance}
      balance -> {:ok, balance}
    end
  end

  def insert_balance(%{"user_id" => user_id, "asset" => asset, "available" => amount} = balance) do
    Repo.insert(
      Balance.changeset(%Balance{}, %{
        "user_id" => user_id,
        "asset_id" => asset,
        "available" => amount
      })
    )
  end

  def update_balance(%{
        "user_id" => user_id,
        "asset" => asset,
        "amount" => amount,
        "operation" => operation
      }) do
    {:ok, balance} = get_balance(user_id, asset)

    case operation do
      :deposit ->
        Repo.update(Balance.changeset(balance, %{available: balance.available + amount}))

      :withdraw ->
        Repo.update(Balance.changeset(balance, %{available: balance.available - amount}))

      :freeze ->
        Repo.update(
          Balance.changeset(balance, %{
            frozen: balance.frozen + amount,
            available: balance.available - amount
          })
        )

      :unfreeze ->
        Repo.update(
          Balance.changeset(balance, %{
            frozen: balance.frozen - amount,
            available: balance.available + amount
          })
        )
    end
  end

  #
  def transfer(%{
        "from_user_id" => from_user_id,
        "to_user_id" => to_user_id,
        "asset" => asset,
        "amount" => amount
      })
      when amount > 0 do
    Repo.transaction(fn ->
      deduct_from_sender(from_user_id, asset, amount)
      add_to_receiver(to_user_id, asset, amount)
    end)
  end

  defp deduct_from_sender(user_id, asset_id, amount) do
    balance = Repo.get_by(Balance, user_id: user_id, asset_id: asset_id)
    new_available = balance.available - amount

    case new_available >= 0 do
      # Deduct the amount and update
      true ->
        changeset = Balance.changeset(balance, %{"available" => new_available})
        Repo.update!(changeset)

      false ->
        {:error, :no_funds}
    end
  end

  defp add_to_receiver(user_id, asset_id, amount) do
    balance = Repo.get_by(Balance, user_id: user_id, asset_id: asset_id)

    case balance do
      nil ->
        {:ok, new_balance} =
          insert_balance(%{"user_id" => user_id, "asset" => asset_id, "available" => amount})

        new_balance

      _ ->
        new_available = balance.available + amount
        changeset = Balance.changeset(balance, %{"available" => new_available})
        Repo.update!(changeset)
    end
  end
end
