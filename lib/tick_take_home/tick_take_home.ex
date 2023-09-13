defmodule TickTakeHome do
  alias TickTakeHome.Models.{Wallet, Balances, Assets, Users}

  def validate_datas(%{"user_id" => user_id, "wallet_id" => wallet_id, "asset" => asset}) do
    case {Assets.get_asset(asset), Users.get_user(user_id), Wallet.get_wallet(wallet_id),
          Balances.get_balance(user_id, asset)} do
      {nil, _, _, _} -> {:error, :missing_asset}
      {_, _, nil, _} -> {:error, :missing_wallet}
      {_, nil, _, _} -> {:error, :missing_user}
      {_, _, _, nil} -> {:error, :missing_balance}
      # tudo ok
      _ -> :ok
    end
  end

  def create_user(wallet_id) do
    Users.create_user(wallet_id)
  end

  def deposit(
        %{
          "user_id" => user_id,
          "asset" => asset,
          "amount" => _amount,
          "wallet_id" => wallet_id
        } = params
      ) do
    case validate_datas(%{"user_id" => user_id, "wallet_id" => wallet_id, "asset" => asset}) do
      {:error, :missing_user} ->
        Users.create_user(user_id, wallet_id)
        insert_balance(params)

      {:error, :missing_balance} ->
        insert_balance(params)

      :ok ->
        handle_operation(params, :deposit)

      error ->
        error
    end
  end

  def withdraw(params), do: handle_operation(params, :withdraw)
  def freeze(params), do: handle_operation(params, :freeze)
  def unfreeze(params), do: handle_operation(params, :unfreeze)

  defp handle_operation(params, operation) do
    case validate_datas(params) do
      :ok ->
        Balances.update_balance(Map.merge(params, %{"operation" => operation}))

      error ->
        error
    end
  end

  defp insert_balance(%{
         "user_id" => user_id,
         "asset_id" => asset,
         "available" => amount,
         "wallet_id" => _
       }) do
    Balances.insert_balance(%{
      "user_id" => user_id,
      "asset_id" => asset,
      "available" => amount
    })
  end
end

# %{"user_id" => 5, "asset" => "BTC", "amount" => 10, "wallet_id" => 5}
