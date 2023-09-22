defmodule TickTakeHomeWeb.TickTakeHomeController do
  use TickTakeHomeWeb, :controller

  alias TickTakeHome.Models.Operations

  def create_user(conn, %{"wallet_id" => wallet_id}) do
    case Operations.start_operation(%{wallet_id: wallet_id, operation: "create_user"}) do
      {:error, error} -> send_resp(conn, 400, error)
      {:ok, response} -> send_resp(conn, 200, response)
    end
  end

  def deposit(conn, %{
        "user_id" => user_id,
        "asset" => asset,
        "amount" => amount,
        "wallet_id" => wallet_id
      }) do
    case Operations.start_operation(%{
           user_id: user_id,
           wallet_id: wallet_id,
           asset: asset,
           amount: amount,
           operation: "deposit"
         }) do
      {:error, error} -> send_resp(conn, 400, error)
      {:ok, response} -> send_resp(conn, 200, response)
    end
  end

  def withdraw(conn, %{"user_id" => user_id, "asset" => asset, "amount" => amount}) do
    case Operations.start_operation(%{
           user_id: user_id,
           asset: asset,
           amount: amount,
           operation: "withdraw"
         }) do
      {:error, error} -> send_resp(conn, 400, error)
      {:ok, response} -> send_resp(conn, 200, response)
    end
  end

  def freeze(conn, %{"user_id" => user_id, "asset" => asset, "amount" => amount}) do
    case Operations.start_operation(%{
           user_id: user_id,
           asset: asset,
           amount: amount,
           operation: "freeze"
         }) do
      {:error, error} -> send_resp(conn, 400, error)
      {:ok, response} -> send_resp(conn, 200, response)
    end
  end

  def unfreeze(conn, %{"user_id" => user_id, "asset" => asset, "amount" => amount}) do
    case Operations.start_operation(%{
           user_id: user_id,
           asset: asset,
           amount: amount,
           operation: "unfreeze"
         }) do
      {:error, error} -> send_resp(conn, 400, error)
      {:ok, response} -> send_resp(conn, 200, response)
    end
  end

  def transfer(conn, %{
        "from_user_id" => from_user_id,
        "to_user_id" => to_user_id,
        "asset" => asset,
        "amount" => amount
      }) do
    case Operations.start_operation(%{
           from_user_id: from_user_id,
           to_user_id: to_user_id,
           asset: asset,
           amount: amount,
           operation: "transfer"
         }) do
      {:error, error} -> send_resp(conn, 400, error)
      {:ok, response} -> send_resp(conn, 200, response)
    end
  end
end
