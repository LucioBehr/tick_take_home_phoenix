defmodule TickTakeHome.Models.Balances.BalancesTest do
  use TickTakeHomeWeb.ConnCase

  alias TickTakeHome.Models.{Wallet, Users, Assets, Balances}

  def insert_asset(_),
    do: Assets.insert_asset("BTC") |> then(fn {:ok, asset} -> %{asset: asset} end)

  def insert_wallet(_),
    do: Wallet.insert_wallet() |> then(fn {:ok, wallet} -> %{wallet: wallet} end)

  def insert_user(%{wallet: wallet}),
    do: Users.create_user(wallet.id) |> then(fn {:ok, user} -> %{user: user} end)

  def insert_second_user(%{wallet: wallet}),
    do:
      Users.create_user(wallet.id)
      |> then(fn {:ok, user_receiver} -> %{user_receiver: user_receiver} end)

  def insert_balance(%{user: user}),
    do:
      Balances.insert_balance(%{"user_id" => user.id, "asset" => "BTC", "available" => 100})
      |> then(fn {:ok, balance} -> %{balance: balance} end)

  describe "insert_balance/1" do
    setup [:insert_wallet, :insert_user, :insert_asset]

    test "it should insert a valid balance", %{wallet: wallet, user: user} do
      result =
        Balances.insert_balance(%{"user_id" => user.id, "asset" => "BTC", "available" => 100})

      user_id = user.id

      assert {:ok, %Balances.Schema.Balance{user_id: ^user_id, asset_id: "BTC", available: 100.0}} =
               result
    end

    test "it should return an invalid user id", %{wallet: wallet, user: user} do
      result =
        Balances.insert_balance(%{"user_id" => 1234, "asset" => "BTC", "available" => 100})

      user_id = user.id
      assert {:error, %_{errors: [user_id: {"does not exist", _}]}} = result
    end

    test "it should return an invalid asset", %{wallet: wallet, user: user} do
      result =
        Balances.insert_balance(%{"user_id" => user.id, "asset" => "aaa", "available" => 100})

      user_id = user.id
      assert {:error, %_{errors: [asset_id: {"does not exist", _}]}} = result
    end
  end

  describe "update_balance/1" do
    setup [:insert_wallet, :insert_user, :insert_asset, :insert_balance]

    test "return the updated balance when depositing", %{user: user, balance: balance} do
      user_id = user.id
      new_available = balance.available + 100

      result =
        Balances.update_balance(%{
          "user_id" => user_id,
          "asset" => "BTC",
          "amount" => 100,
          "operation" => :deposit
        })

      assert {:ok,
              %Balances.Schema.Balance{
                user_id: ^user_id,
                asset_id: "BTC",
                available: new_available
              }} = result
    end

    test "return no funds when attempting to withdraw more than what is in the balance", %{
      user: user,
      balance: balance
    } do
      user_id = user.id

      result =
        Balances.update_balance(%{
          "user_id" => user_id,
          "asset" => "BTC",
          "amount" => 1000,
          "operation" => :withdraw
        })

      assert {:error, :no_funds} = result
    end

    test "it should return an invalid operation", %{wallet: wallet, user: user, balance: balance} do
      result =
        Balances.update_balance(%{
          "user_id" => user.id,
          "asset" => "BTC",
          "amount" => 100,
          "operation" => :invalid_operation
        })

      user_id = user.id
      assert {:error, :unsupported_operation} = result
    end

    test "it should return an invalid balance", %{wallet: wallet, user: user, balance: balance} do
      result =
        Balances.update_balance(%{
          "user_id" => 999,
          "asset" => "BTC",
          "amount" => 100,
          "operation" => :withdraw
        })

      user_id = user.id
      assert {:error, :no_balance} = result
    end
  end

  describe "transfer/1" do
    setup [:insert_wallet, :insert_user, :insert_asset, :insert_balance, :insert_second_user]

    test "return the updated balances when transfering", %{
      user: user,
      balance: balance,
      user_receiver: user_receiver
    } do
      user_id = user.id
      user_receiver_id = user_receiver.id
      new_available = balance.available - 100
      new_available_receiver = 100

      result =
        Balances.transfer(%{
          "from_user_id" => user_id,
          "to_user_id" => user_receiver_id,
          "asset" => "BTC",
          "amount" => 100
        })

      assert {:ok,
              %Balances.Schema.Balance{
                user_id: ^user_receiver_id,
                asset_id: "BTC",
                available: new_available_receiver
              }} = result
    end

    test "return no funds when attempting to transfer more than what is in the balance", %{
      user: user,
      balance: balance,
      user_receiver: user_receiver
    } do
      user_id = user.id
      user_receiver_id = user_receiver.id

      result =
        Balances.transfer(%{
          "from_user_id" => user_id,
          "to_user_id" => user_receiver_id,
          "asset" => "BTC",
          "amount" => 1000
        })

      assert {:error, :no_funds} = result
    end

    test "it should return an invalid balance", %{
      wallet: wallet,
      user: user,
      balance: balance,
      user_receiver: user_receiver
    } do
      result =
        Balances.transfer(%{
          "from_user_id" => 999,
          "to_user_id" => user_receiver.id,
          "asset" => "BTC",
          "amount" => 100
        })

      user_id = user.id
      assert {:error, :no_balance} = result
    end
  end

  describe "get_balance/2" do
    setup [:insert_wallet, :insert_user, :insert_asset, :insert_balance]

    test "return balance based on user and asset", %{user: user, balance: balance} do
      user_id = user.id
      available = balance.available
      result = Balances.get_balance(user_id, "BTC")

      assert {:ok,
              %Balances.Schema.Balance{user_id: ^user_id, asset_id: "BTC", available: available}} =
               result
    end

    test "it should return an invalid balance", %{wallet: wallet, user: user, balance: balance} do
      result = Balances.get_balance(999, "BTC")
      user_id = user.id
      assert {:error, :no_balance} = result
    end
  end
end
