defmodule TickTakeHomeWeb.TransactionCoordinator.Logic do

  @doc """
  Starts a new transaction based on the provided wallet transfer data.

  This function initiates a transaction by parsing the transfer details and appending the transaction with a unique ID, setting its status to "pending", and listing the operations parsed from the transfer data. The newly formed transaction is then prepended to the list of transactions in the `state_data`.

  ## Parameters

    - `transfer_wallet_data`: A map containing the details of the wallet transfer. The exact structure is not detailed in the provided code.
    - `state_data`: A map which holds the current state, including a list of transactions and the last completed transaction's ID.

  ## Return

    - Returns an updated `state_data` with the new transaction added to the `transactions_list`.

  ## Notes

    - The function relies on the `parse_transactions/1` function to extract operations from the `transfer_wallet_data`. The behavior of this function should be considered when using `start_transaction/2`.
    - Transactions are assigned unique IDs by incrementing the `last_complete_id` from the `state_data`.

  ## Example usage:
  transfer_wallet_data =
      %{
      "asset" => "ETH",
      "from_wallet_id" => 1,
      "from_user_id" => 1,
      "to_wallet_id" => 2,
      "to_user_id" => 2,
      "amount" => 10
    }
  coordinator_state = %{
    "last_complete_id" => 0,
    "transactions_list" => []
  }
  start_transaction(transfer_wallet_data_0, coordinator_state)
  coordinator_state = %{
      "last_complete_id" => 0,
      "transactions_list" => [
        %{
          "id" => 1,
          "asset" => "ETH",
          "from_wallet_id" => 1,
          "from_user_id" => 1,
          "to_wallet_id" => 2,
          "to_user_id" => 2,
          "amount" => 10,
          "status" => "pending"
          "operations" => [
              %{
                "event" => :withdraw,
                "process_name" => :wallet_1,
                "args" => %{"asset" => "ETH", "amount" => 10, "user_id" => 1}
              },
              %{
                "event" => :deposit,
                "process_name" => :wallet_2,
                "args" => %{"asset" => "ETH", "amount" => 10, "user_id" => 2}
              }
            ]
        }
      ]
    }
  """
  def start_transaction(transfer_wallet_data, coordinator_state) do
    operations = parse_transactions(transfer_wallet_data)

    coordinator_transaction_info = %{
      "id" => coordinator_state["last_complete_id"] + 1,
      "status" => "pending",
      "operations" => operations
    }

    new_transaction = Map.merge(transfer_wallet_data, coordinator_transaction_info)

    Map.update!(coordinator_state, "transactions_list", fn transactions ->
      [new_transaction | transactions]
    end)
  end

  @doc """
  Parses transaction details to create a list of operations: withdrawal and deposit.

  This function generates a list of two operations based on the provided transaction details:
  1. A withdrawal from the source wallet (`from_wallet_id`).
  2. A deposit into the destination wallet (`to_wallet_id`).

  ## Parameters

    - A map with the following keys:
      - `"asset"`: The type of asset (e.g., "USD", "BTC") involved in the transaction.
      - `"from_wallet_id"`: The ID of the source wallet from which the amount will be withdrawn.
      - `"from_user_id"`: The ID of the user associated with the source wallet.
      - `"to_wallet_id"`: The ID of the destination wallet where the amount will be deposited.
      - `"to_user_id"`: The ID of the user associated with the destination wallet.
      - `"amount"`: The amount of the asset to be transferred.

  ## Return

    - Returns a list containing two maps:
      1. The withdrawal operation with details such as event type (`:withdraw`), process name based on the source wallet, and the arguments (asset type, amount, user ID).
      2. The deposit operation with details such as event type (`:deposit`), process name based on the destination wallet, and the arguments (asset type, amount, user ID).

  ## Example usage:

      iex> parse_transactions(%{"asset" => "BTC", "from_wallet_id" => "001", "from_user_id" => "userA", "to_wallet_id" => "002", "to_user_id" => "userB", "amount" => 1.5})
      [
        %{
          "event" => :withdraw,
          "process_name" => :"wallet_001",
          "args" => %{"asset" => "BTC", "amount" => 1.5, "user_id" => "userA"}
        },
        %{
          "event" => :deposit,
          "process_name" => :"wallet_002",
          "args" => %{"asset" => "BTC", "amount" => 1.5, "user_id" => "userB"}
        }
      ]

"""
  def parse_transactions(%{
        "asset" => asset,
        "from_wallet_id" => from_wallet_id,
        "from_user_id" => from_user_id,
        "to_wallet_id" => to_wallet_id,
        "to_user_id" => to_user_id,
        "amount" => amount
      }) do
    [
      %{
        "event" => :withdraw,
        "process_name" => :"wallet_#{from_wallet_id}",
        "args" => %{"asset" => asset, "amount" => amount, "user_id" => from_user_id}
      },
      %{
        "event" => :deposit,
        "process_name" => :"wallet_#{to_wallet_id}",
        "args" => %{"asset" => asset, "amount" => amount, "user_id" => to_user_id}
      }
    ]
  end

  @doc """
  Sends a call to a GenServer to execute a specific event.

  This function takes an operation map detailing an event, the GenServer's process name, and the associated arguments. It then sends a call to the specified GenServer, instructing it to execute the event.

  ## Parameters

    - A map with the following keys:
      - `"event"`: The type of event (e.g., `:deposit`, `:withdraw`) to be executed by the GenServer.
      - `"process_name"`: The name (or identifier) of the GenServer that will handle the event.
      - `"args"`: A map containing the arguments required to execute the event.
    - `coordinator_id`: An identifier associated with the coordinator or initiating process.

  ## Return

    - Returns the result of the GenServer call, which could vary depending on the handling of the event in the specified GenServer.

  ## Notes

    - The behavior of this function largely depends on the implementation of the GenServer associated with `process_name` and how it handles the specified event.

  ## Example usage:

      iex> execute_step(%{"event" => :deposit, "process_name" => :my_wallet, "args" => %{"amount" => 100}}, 2)
      {:ok, "Deposited 100 units"}
    execute_step calls TickTakeHome.Wallet.handle_call with the first argument having 3 parameters
    It changes the wallet's state_data and the coordinator_id in the .json file.
"""
  def execute_step(
        %{"event" => event, "process_name" => process_name, "args" => args},
        coordinator_id
      ) do
    GenServer.call(process_name, {event, args, coordinator_id})
  end

  def revert_step(
    %{"event" => event, "process_name" => process_name, "args" => args},
    coordinator_id
  ) do
    GenServer.call(process_name, {:"revert_#{event}", args, coordinator_id})
  end


  @doc """
  Finalizes the most recent transaction in the state's transaction list.

  This function updates the status of the most recent (or the first) transaction in the `transactions_list` to "finished". It also sets the `last_complete_id` field in the state to the ID of this recently finalized transaction.

  ## Parameters

    - A map with a key `"transactions_list"`:
      - `"transactions_list"`: A list where the first element is the most recent transaction (to be finalized). This transaction should at least have an `"id"` field. The remaining elements are other past transactions.

  ## Return

    - Returns an updated state where:
      1. The status of the most recent transaction is set to "finished".
      2. The `last_complete_id` is updated to the ID of the recently finalized transaction.

  ## Notes

    - This function assumes that the `transactions_list` is ordered such that the most recent transaction is at the beginning of the list.

  ## Example

      iex> finalize_transaction(%{"transactions_list" => [%{"id" => 3, "status" => "pending"}, %{"id" => 2}, %{"id" => 1}]})
      %{
        "transactions_list" => [%{"id" => 3, "status" => "finished"}, %{"id" => 2}, %{"id" => 1}],
        "last_complete_id" => 3
      }

"""
  def finalize_transaction(
        %{"transactions_list" => [%{"id" => id} = last_transaction | rest_transactions]} = state
      ),
      do: %{
        state
        | "transactions_list" => [
            %{
              last_transaction
              | "id" => id,
                "status" => "finished"
            }
            | rest_transactions
          ],
          "last_complete_id" => id
      }

  def revert_transaction(
        %{"transactions_list" => [%{"id" => id} = last_transaction | rest_transactions]} = state
      ),
      do: %{
        state
        | "transactions_list" => [
            %{
              last_transaction
              | "id" => id,
                "status" => "aborted"
            }
            | rest_transactions
          ]
      }
end
