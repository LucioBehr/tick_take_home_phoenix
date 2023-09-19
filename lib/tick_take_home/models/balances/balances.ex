defmodule TickTakeHome.Models.Balances do
  alias TickTakeHome.Models.Balances.Repositories.Database

  def get_balance(user_id, asset) do
    Database.get_balance(user_id, asset)
  end

  def insert_balance(balance) do
    Database.insert_balance(balance)
  end

  def update_balance(%{"user_id" => user_id, "asset" => asset, "amount" => amount, "operation" => operation} = balance) do
    {_, user_balance} = get_balance(user_id, asset)
    case get_balance(user_id, asset) do
      {:ok, _struct} ->
        case operation do
          :deposit -> Database.update_balance(balance)
          :withdraw -> do_update_with_check(user_balance.available, balance)
          :freeze -> do_update_with_check(user_balance.available, balance)
          :unfreeze -> do_update_with_check(user_balance.frozen, balance)
          _ -> {:error, :unsupported_operation}
        end
      {:error, _} ->
        {:error, :no_balance}
    end
  end

  defp do_update_with_check(checker, balance) do
    case checker >= balance["amount"] do
      true -> Database.update_balance(balance)
      false -> {:error, :no_funds}
    end
  end

  def transfer(%{"from_user_id" => from_user_id, "to_user_id" => to_user_id, "asset" => asset, "amount" => amount}) do
    case get_balance(from_user_id, asset) do
      #{:ok, %{available: available}}
      {:ok, %{available: available}} when available >= amount ->
        Database.transfer(%{"from_user_id" => from_user_id, "to_user_id" => to_user_id, "asset" => asset, "amount" => amount})

      {:ok, %{available: _available}} ->
        {:error, :no_funds}

      {:error, _} ->
        {:error, :no_balance}
    end
  end
end
