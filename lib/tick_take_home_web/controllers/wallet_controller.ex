defmodule TickTakeHomeWeb.WalletController do
  use TickTakeHomeWeb, :controller

  import TickTakeHome.Macros
  alias TickTakeHomeWeb.Wallet

  def deposit(conn, args), do:
    guard_valid_name("wallet", 100, args, do:
      Wallet.deposit(name, data)
      |> Jason.encode!()
      |> then(&send_resp(conn, 200, &1)), else: conn |> send_resp(400, "Invalid request"))

  def get_all(conn, args) do
    guard_valid_name("wallet", 100, args) do
      Wallet.get_all(name)
      |> Jason.encode!()
      |> then(&send_resp(conn, 200, &1))
    else
      conn |> send_resp(400, "Invalid request")
    end |> IO.inspect()
  end

  def withdraw(conn, args), do:
    guard_valid_name("wallet", 100, args, do:
      Wallet.withdraw(name, data)
      |> Jason.encode!()
      |> then(&send_resp(conn, 200, &1)), else: conn |> send_resp(400, "Invalid request"))

  def transfer(conn, args), do:
    guard_valid_name("wallet", 100, args, do:
      Wallet.transfer(name, data)
      |> Jason.encode!()
      |> then(&send_resp(conn, 200, &1)), else: conn |> send_resp(400, "Invalid request"))

  def freeze(conn, args), do:
    guard_valid_name("wallet", 100, args, do:
      Wallet.freeze(name, data)
      |> Jason.encode!()
      |> then(&send_resp(conn, 200, &1)), else: conn |> send_resp(400, "Invalid request"))

  def unfreeze(conn, args), do:
    guard_valid_name("wallet", 100, args, do:
      Wallet.unfreeze(name, data)
      |> Jason.encode!()
      |> then(&send_resp(conn, 200, &1)), else: conn |> send_resp(400, "Invalid request"))

  def revert_deposit(conn, args) do
    response =
    Wallet.revert_deposi(args)
    |> Jason.encode!()
    send_resp(conn, 200, response)
  end

  def revert_withdraw(conn, args) do
    response =
    Wallet.revert_withdraw(args)
    |> Jason.encode!()
    send_resp(conn, 200, response)
  end
end
