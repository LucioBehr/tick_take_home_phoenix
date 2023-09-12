defmodule TickTakeHome.Models.Balances do
  alias TickTakeHome.Models.Balances.Repositories.Database

  def get_balance(user_id, asset) do
    Database.get_balance(user_id, asset)
  end

  def insert_balance(%{"user_id" => user_id, "asset_id" => asset} = balance) do
    Database.insert_balance(balance)
  end

  def update_balance(%{"operation" => :deposit} = balance) do
    Database.update_balance(balance)
  end

  def update_balance(%{"user_id" => user_id, "asset" => asset, "amount" => amount, "operation" => :withdraw} = balance) do
    case get_balance(user_id, asset) |>IO.inspect() do
      %{available: available} when available >= amount ->
        Database.update_balance(balance)
      %{available: available} ->
        {:error, :no_funds}
      _ ->
          {:error, :no_balance}
    end
  end

  def update_balance(%{"user_id" => user_id, "asset" => asset, "amount" => amount, "operation" => :freeze} = balance) do
    case get_balance(user_id, asset) do
      %{available: available} when available >= amount ->
        Database.update_balance(balance)
      %{available: available} ->
          {:error, :no_funds}
      _ ->
        {:error, :no_balance}
      end
    end

  def update_balance(%{"user_id" => user_id, "asset" => asset, "amount" => amount, "operation" => :unfreeze} = balance) do
    case get_balance(user_id, asset) do
    %{frozen: frozen} when frozen >= amount ->
      Database.update_balance(balance)
    %{frozen: frozen} ->
        {:error, :no_funds}
    _ ->
      {:error, :no_balance}
    end
  end
end
