defmodule Integration.IntegrationTest do
  alias TickTakeHome.Models.Repositories.KafkaProducer
  alias TickTakeHome.KafkaConsumer
  alias TickTakeHome.Models.{Wallet, Users, Assets, Balances}
  use TickTakeHomeWeb.ConnCase

  def insert_asset(_),
    do: Assets.insert_asset("BTC") |> then(fn {:ok, asset} -> %{asset: asset} end)

  def insert_wallet(_),
    do: Wallet.insert_wallet() |> then(fn {:ok, wallet} -> %{wallet: wallet} end)

  def insert_user(%{wallet: wallet}),
    do: Users.create_user(wallet.id) |> then(fn {:ok, user} -> %{user: user} end)

  def insert_balance(%{user: user}),
    do:
      Balances.insert_balance(%{"user_id" => user.id, "asset" => "BTC", "available" => 10})
      |> then(fn {:ok, balance} -> %{balance: balance} end)

  def insert_second_user(%{wallet: wallet}),
    do:
      Users.create_user(wallet.id)
      |> then(fn {:ok, user_receiver} -> %{user_receiver: user_receiver} end)

  def insert_balance_frozen(%{user_receiver: user_receiver}) do
      Balances.insert_balance(%{"user_id" => user_receiver.id, "asset" => "BTC", "available" => 10})
      Balances.update_balance(%{
        "user_id" => user_receiver.id,
        "asset" => "BTC",
        "amount" => 10,
        "operation" => :freeze
      })
      |> then(fn {:ok, balance} -> %{balance: balance} end)
  end

  def user_insert_balance(context, available) do
    %{user: user} = context
    Balances.insert_balance(%{"user_id" => user.id, "asset" => "BTC", "available" => available})
    |> then(fn {:ok, balance} -> %{balance: balance} end)
  end

  # def insert_balance(%{user: user}),
  #   do: Balances.insert_balance("user_id" => user.id, "asset" => "BTC", "available" => 10.0) |> then(fn {:ok, balance} -> %{balance: balance} end)

  describe "Create user" do
    test "user is created" do
      # Mock the KafkaProducer.operation/1 function
      with_mock KafkaProducer, operation: fn _data -> :ok end do
        # Call the function you're testing here
        result =
          TickTakeHome.Models.Operations.start_operation(%{wallet_id: 1, operation: "create_user"})

        assert {:ok, "User creation request sent"} == result
      end
    end
  end

  describe "Deposit flux" do
    @tag :deposit_flux
    setup [:insert_wallet, :insert_asset]
    test "user can deposit", %{wallet: wallet} do
      with_mock KafkaProducer, operation: fn _value -> :ok end do
        conn = build_conn()

        conn =
          post(conn, "/deposit", %{
            "user_id" => 1,
            "asset" => "BTC",
            "amount" => 10,
            "wallet_id" => wallet.id
          })

        deposit_message = %{
          user_id: 1,
          asset: "BTC",
          amount: 10.0,
          wallet_id: wallet.id,
          operation: "deposit"
        }

        assert conn.resp_body == "Deposit request sent"
        assert_called(KafkaProducer.operation(deposit_message))

        KafkaConsumer.handle_message(
          "first",
          0,
          {:kafka_message, "", "deposit", Jason.encode!(deposit_message), "", 123_455_679, ""},
          "state"
        )

        assert {:ok, %Balances.Schema.Balance{available: 10.0, user_id: 1, asset_id: "BTC"}} = Balances.get_balance(1, "BTC")
      end
    end
    @tag :deposit_error_no_balance
    test "error of no balance (wallet doesn't exist)", %{wallet: wallet} do
      with_mock KafkaProducer, operation: fn _value -> :error end do
        conn = build_conn()

        conn =
          post(conn, "/deposit", %{
            "user_id" => 1,
            "asset" => "BTC",
            "amount" => 10,
            "wallet_id" => -5
          })

        deposit_message = %{
          user_id: 1,
          asset: "BTC",
          amount: 10.0,
          wallet_id: -5,
          operation: "deposit"
        }

        assert conn.resp_body == "Deposit request sent"
        assert_called(KafkaProducer.operation(deposit_message))

        KafkaConsumer.handle_message(
          "first",
          0,
          {:kafka_message, "", "deposit", Jason.encode!(deposit_message), "", 123_455_679, ""},
          "state"
        )
        assert {:error, :no_balance} = Balances.get_balance(1, "BTC")
      end
    end
  end

  describe "Withdraw flux" do
    @tag :withdraw_success
    setup [:insert_wallet, :insert_user, :insert_asset]

    setup context do
      user_insert_balance(context, 10)
    end

    test "user can withdraw", %{user: user} do
      with_mock KafkaProducer, operation: fn _value -> :ok end do
        user_id = user.id
        conn = build_conn()

        conn =
          post(conn, "/withdraw", %{
            "user_id" => user_id,
            "asset" => "BTC",
            "amount" => 5
          })

        withdraw_message = %{
          user_id: user_id,
          asset: "BTC",
          amount: 5.0,
          operation: "withdraw"
        }

        assert conn.resp_body == "Withdraw request sent"
        assert_called(KafkaProducer.operation(withdraw_message))


        KafkaConsumer.handle_message(
          "first",
          0,
          {:kafka_message, "", "withdraw", Jason.encode!(withdraw_message), "", 123_455_679, ""},
          "state"
        )

        assert {:ok, %Balances.Schema.Balance{available: 5.0, user_id: user_id, asset_id: "BTC"}} = Balances.get_balance(user_id, "BTC")
      end
    end

    @tag :withdraw_error_no_funds
    test "error of no funds", %{user: user} do
      with_mock KafkaProducer, operation: fn _value -> :error end do
        previous_balance = Balances.get_balance(user.id, "BTC")

        conn = build_conn()

        conn =
          post(conn, "/withdraw", %{
            "user_id" => user.id,
            "asset" => "BTC",
            "amount" => 15
          })

        withdraw_message = %{
          user_id: user.id,
          asset: "BTC",
          amount: 15.0,
          operation: "withdraw"
        }

        assert conn.resp_body == "Withdraw request sent"
        assert_called(KafkaProducer.operation(withdraw_message))

        KafkaConsumer.handle_message(
          "first",
          0,
          {:kafka_message, "", "withdraw", Jason.encode!(withdraw_message), "", 123_455_679, ""},
          "state"
        )
        assert previous_balance == Balances.get_balance(user.id, "BTC")
      end
    end
  end

  describe "freeze flux" do
    @tag :freeze_success
    setup [:insert_wallet, :insert_user, :insert_asset, :insert_balance]
    test "freeze/1", %{user: user} do

      with_mock KafkaProducer, operation: fn _value -> :ok end do
        conn = build_conn()
        user_id = user.id
        conn =
          post(conn, "/freeze", %{
            "user_id" => user_id,
            "asset" => "BTC",
            "amount" => 5
          })

        freeze_message = %{
          user_id: user_id,
          asset: "BTC",
          amount: 5.0,
          operation: "freeze"
        }

        assert conn.resp_body == "Freeze request sent"
        assert_called(KafkaProducer.operation(freeze_message))

        KafkaConsumer.handle_message(
          "first",
          0,
          {:kafka_message, "", "freeze", Jason.encode!(freeze_message), "", 123_455_679, ""},
          "state"
        )

        assert {:ok, %Balances.Schema.Balance{frozen: 5.0, user_id: user_id, asset_id: "BTC"}} = Balances.get_balance(user_id, "BTC")
      end
    end
  end

  describe "unfreeze flux" do
    @tag :unfreeze_success
    setup [:insert_wallet, :insert_asset, :insert_second_user, :insert_balance_frozen]
    test "unfreeze/1", %{user_receiver: user_receiver} do
      with_mock KafkaProducer, operation: fn _value -> :ok end do
        conn = build_conn()
        user_id = user_receiver.id
        conn =
          post(conn, "/unfreeze", %{
            "user_id" => user_id,
            "asset" => "BTC",
            "amount" => 5
          })

        unfreeze_message = %{
          user_id: user_id,
          asset: "BTC",
          amount: 5.0,
          operation: "unfreeze"
        }

        assert conn.resp_body == "Unfreeze request sent"
        assert_called(KafkaProducer.operation(unfreeze_message))

        KafkaConsumer.handle_message(
          "first",
          0,
          {:kafka_message, "", "unfreeze", Jason.encode!(unfreeze_message), "", 123_455_679, ""},
          "state"
        )
        assert {:ok, %Balances.Schema.Balance{available: 5.0, user_id: user_id, asset_id: "BTC"}} = Balances.get_balance(user_id, "BTC")
      end
    end
  end

   describe "transfer flux" do
     setup [:insert_wallet, :insert_user, :insert_asset, :insert_balance, :insert_second_user]
     @tag :transfer_success
     test "transfer/1", %{user: user, user_receiver: user_receiver} do
       with_mock KafkaProducer, operation: fn _value -> :ok end do
         conn = build_conn()
         user_id = user.id
         user_receiver_id = user_receiver.id
         conn =
           post(conn, "/transfer", %{
             "from_user_id" => user.id,
             "to_user_id" => user_receiver.id,
             "asset" => "BTC",
             "amount" => 10
           })
         transfer_message = %{
           from_user_id: user_id,
           to_user_id: user_receiver_id,
           asset: "BTC",
           amount: 10.0,
           operation: "transfer"
         }
         assert conn.resp_body == "Transfer request sent"
         assert_called(KafkaProducer.operation(transfer_message))
         KafkaConsumer.handle_message(
           "first",
           0,
           {:kafka_message, "", "transfer", Jason.encode!(transfer_message), "", 123_455_679, ""},
           "state"
         )
         assert {:ok, %Balances.Schema.Balance{available: 0.0, user_id: user_id, asset_id: "BTC"}} = Balances.get_balance(user_id, "BTC")
         assert {:ok, %Balances.Schema.Balance{available: 10.0, user_id: user_receiver_id, asset_id: "BTC"}} = Balances.get_balance(user_receiver_id, "BTC")
       end
     end
   end

end
