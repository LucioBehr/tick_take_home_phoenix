defmodule TickTakeHome do
  alias TickTakeHome.Models.{Wallet, Balances, Assets, Users}


  def validate_datas(%{"user_id" => user_id, "wallet_id" => wallet_id, "asset" => asset}) do
    case {Assets.get_asset(asset), Users.get_user(user_id), Wallet.get_wallet(wallet_id)} do
      {nil, _, _} -> {:error, :missing_asset}
      {_, _, nil} -> {:error, :missing_wallet}
      {_, nil, _} -> {:error, :missing_user}
      _ -> :ok # tudo ok
    end
  end

  def create_user(wallet_id) do
    Users.create_user(wallet_id)
  end

  def deposit(%{"user_id" => user_id, "asset" => asset, "amount" => amount, "wallet_id" => wallet_id}) do
    case {validate_datas(%{"user_id" => user_id, "wallet_id" => wallet_id, "asset" => asset}), Balances.get_balance(user_id, asset)} do
      {{:error, :missing_user}, _balance} ->
        Users.create_user(user_id, wallet_id)
        Balances.insert_balance(%{"user_id" => user_id, "asset_id" => asset, "available" => amount})
      {:ok, nil} -> Balances.insert_balance(%{"user_id" => user_id, "asset_id" => asset, "available" => amount})
      {:ok, _} -> Balances.update_balance(%{"user_id" => user_id, "asset" => asset, "amount" => amount, "operation" => :deposit})
      error -> error
    end
  end

  def withdraw(%{"user_id" => user_id, "asset" => asset, "amount" => amount, "wallet_id" => wallet_id}) do
    case {validate_datas(%{"user_id" => user_id, "wallet_id" => wallet_id, "asset" => asset}), Balances.get_balance(user_id, asset)} do
      {:ok, nil} -> {:error, :missing_balance}
      {:ok, _} -> Balances.update_balance(%{"user_id" => user_id, "asset" => asset, "amount" => amount, "operation" => :withdraw})
      error -> error
    end
  end

  def freeze(%{"user_id" => user_id, "asset" => asset, "amount" => amount, "wallet_id" => wallet_id}) do
    case {validate_datas(%{"user_id" => user_id, "wallet_id" => wallet_id, "asset" => asset}), Balances.get_balance(user_id, asset)} do
      {:ok, nil} -> {:error, :missing_balance}
      {:ok, _} -> Balances.update_balance(%{"user_id" => user_id, "asset" => asset, "amount" => amount, "operation" => :freeze})
      error -> error
    end
  end

  def unfreeze(%{"user_id" => user_id, "asset" => asset, "amount" => amount, "wallet_id" => wallet_id}) do
    case {validate_datas(%{"user_id" => user_id, "wallet_id" => wallet_id, "asset" => asset}), Balances.get_balance(user_id, asset)} do
      {:ok, nil} -> {:error, :missing_balance}
      {:ok, _} -> Balances.update_balance(%{"user_id" => user_id, "asset" => asset, "amount" => amount, "operation" => :unfreeze})
      error -> error
    end
  end
end
