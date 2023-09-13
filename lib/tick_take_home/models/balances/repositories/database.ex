defmodule TickTakeHome.Models.Balances.Repositories.Database do
  alias TickTakeHome.Models.Balances.Schema.Balance
  alias TickTakeHome.Repo
  import Ecto.Query

  def get_balance(user_id, asset) do
    Repo.one(from b in Balance, where: b.user_id == ^user_id and b.asset_id == ^asset)
  end

  def insert_balance(%{"user_id" => user_id, "asset_id" => asset, "available" => amount}) do
    Repo.insert!(
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
    balance = get_balance(user_id, asset)

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
  def transfer(sender_id, receiver_id, asset_id, amount) when amount > 0 do
    Repo.transaction(fn ->
      deduct_from_sender(sender_id, asset_id, amount)
      add_to_receiver(receiver_id, asset_id, amount)
    end)
  end

  defp deduct_from_sender(user_id, asset_id, amount) do
    balance = Repo.get_by(Balance, user_id: user_id, asset_id: asset_id)
    new_available = balance.available - amount

    case new_available >= 0 do
      true ->  # Deduct the amount and update
        changeset = Balance.changeset(balance, %{"available" => new_available})
        Repo.update!(changeset)
      false -> {:error, :no_funds}
    end
  end

  defp add_to_receiver(user_id, asset_id, amount) do
    balance = Repo.get_by(Balance, user_id: user_id, asset_id: asset_id)

    case balance do
      nil -> insert_balance(%{"user_id" => user_id, "asset_id" => asset_id, "available" => amount})

      _ ->
        new_available = balance.available + amount
        changeset = Balance.changeset(balance, %{"available" => new_available})
        Repo.update!(changeset)
    end
  end
end
