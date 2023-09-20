defmodule TickTakeHome do
  alias TickTakeHome.Models.{Wallet, Balances, Assets, Users}

  def validate_datas(%{"user_id" => user_id, "asset" => asset}) do
    case {Assets.get_asset(asset), Users.get_user(user_id), Balances.get_balance(user_id, asset)} do
      {nil, _, _} -> {:error, :missing_asset}
      {_, nil, _} -> {:error, :missing_user}
      {_, _, {:error, :no_balance}} -> {:error, :no_balance}
      _ -> :ok
    end
  end

  def create_user(wallet_id) do
    case Wallet.get_wallet(wallet_id) do
      nil -> {:error, :missing_wallet}
      _ -> Users.create_user(wallet_id)
    end
  end

  def deposit(
        %{
          "user_id" => user_id,
          "asset" => asset,
          "amount" => _amount,
          "wallet_id" => wallet_id
        } = params
      ) do
    case validate_datas(%{"user_id" => user_id, "asset" => asset}) do
      {:error, :missing_user} ->
        Users.create_user(user_id, wallet_id)
        insert_balance(params)

      {:error, :no_balance} ->
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

  def transfer(
        %{
          "from_user_id" => from_user_id,
          "to_user_id" => to_user_id,
          "asset" => asset,
          "amount" => _amount
        } = params
      ) do
    case {validate_datas(%{"user_id" => from_user_id, "asset" => asset}),
          Users.get_user(to_user_id)} do
      {{:error, reason}, _} ->
        {:error, reason}

      {:ok, nil} ->
        {:error, :missing_user}

      {:ok, _} ->
        Balances.transfer(params)
    end
  end

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
