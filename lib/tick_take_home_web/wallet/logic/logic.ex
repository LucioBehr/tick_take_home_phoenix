defmodule TickTakeHomeWeb.Wallet.Logic do
  @moduledoc """
  This module deals with the logic behind internal wallet operations,
  such as deposit, withdraw, freeze, unfreeze, and transfers between users within the same wallet.
  """

  @doc """
  Deposits a specific amount of an asset for a user.
  The function accepts a map containing `user_id`, `asset`, and `amount` as keys.
  It updates the available quantity of that asset for the user in the given state.

  ## Parameters
    - `params`: A map with the following keys:
      - `"user_id"`: The user's ID.
      - `"asset"`: The type of asset being deposited.
      - `"amount"`: The amount of the asset to be deposited.
    - `state_data`: The current state containing user data.

  ## Returns
    - `{:ok, message, new_state_data}`: If the deposit was successful.
    - `:ok`: An atom indicating success.
    - A string message detailing the deposit made.
    - The `new_state_data`, which is the updated state after the deposit.

  ## Example usage:
  deposit_data_1 = %{"user_id" => 1, "asset" => "BTC", "amount" => 10}
  state_data_0 = %{ "users" => %{ 1 => %{ "BTC" => %{ "frozen" => 0.0, "available" => 10.0}}}}
  Wallet.deposit(deposit_data_1, state_data)
  #=> %{ "users" => %{ 1 => %{ "BTC" => %{ "frozen" => 0.0, "available" => 20.0}}}}
  """
  def deposit(%{"user_id" => user_id, "asset" => asset, "amount" => amount}, state_data) do
    new_state_data =
      state_data
      |> Map.update(
        "users",
        %{user_id => %{asset => %{"frozen" => 0, "available" => amount}}},
        fn users ->
          users
          |> Map.update(user_id, %{asset => %{"frozen" => 0, "available" => amount}}, fn user ->
            user
            |> Map.update(asset, %{"frozen" => 0, "available" => amount}, fn asset ->
              asset
              |> Map.update("available", 0, fn old_available -> old_available + amount end)
            end)
          end)
        end
      )

    {:ok, "Deposited #{amount} #{asset} for user #{user_id}", new_state_data}
  end

  @doc """
    Withdraws a specific amount of an asset for a user.

    This function accepts a map containing the keys: `user_id`, `asset`, and `amount`.
    It then updates the available balance of that asset for the specified user in the given state.

    If the specified `amount` to withdraw exceeds the available balance for the user, an error will be raised.

    ## Parameters

      - `params`: A map with the following keys:
        - `"user_id"`: The ID of the user for whom the withdrawal will be processed.
        - `"asset"`: The type of asset (e.g., "USD", "BTC") being withdrawn.
        - `"amount"`: The amount of the asset to be withdrawn.
      - `state_data`: The current state containing data for all users.

    ## Return

      - In case of successful withdrawal:
        Returns a tuple with the atom `:ok`, a string message detailing the withdrawal, and the updated `state_data`.

      - In case of insufficient balance:
        Returns a tuple with the atom `:error`, an error message indicating insufficient balance, and the unchanged `state_data`.

    ## Examples

        iex> Wallet.withdraw(%{"user_id" => "123", "asset" => "USD", "amount" => 50}, %{"users" => %{"123" => %{"USD" => %{"available" => 100}}}})
        {:ok, "Withdrawn 50 USD for user 123", %{"users" => %{"123" => %{"USD" => %{"available" => 50}}}}}

        iex> withdraw(%{"user_id" => "123", "asset" => "USD", "amount" => 150}, %{"users" => %{"123" => %{"USD" => %{"available" => 100}}}})
        {:error, "Not Enough Balance", %{"users" => %{"123" => %{"USD" => %{"available" => 100}}}}}
  """

  def withdraw(%{"user_id" => user_id, "asset" => asset, "amount" => amount}, state_data) do
    new_state_data =
      state_data
      |> Map.update!("users", fn users ->
        users
        |> Map.update!(user_id, fn user ->
          user
          |> Map.update!(asset, fn asset ->
            asset
            |> Map.update!("available", fn
              old_available when amount <= old_available -> old_available - amount
              old_available when amount > old_available -> raise "Not Enough Balance"
            end)
          end)
        end)
      end)

    {:ok, "Withdrawn #{amount} #{asset} for user #{user_id}", new_state_data}
  rescue
    _ -> {:error, "Not Enough Balance", state_data}
  end

  @doc """
  Transfer a specific amount of an asset between users within the same wallet.
  The function accepts a map containing `from_user_id`, `to_user_id`, `asset` and `amount` as keys.
  It updates the available quantity of that asset for the user in the given state.

  ## Parameters
    - `params`: A map with the following keys:
      - `"from_user_id"`: Sender's user's ID.
      - `"to_user_id"`: Receiver's user's ID.
      - `"asset"`: The type of asset being deposited.
      - `"amount"`: The amount of the asset to be deposited.
    - `state_data`: The current state containing user data.

  ## Returns
    - `{:ok, message, new_state_data}`: If the deposit was successful.
    - `:ok`: An atom indicating success.
    - A string message detailing the deposit made.
    - The `new_state_data`, which is the updated state after the deposit.

  ## Example usage:
  transfer_data_1 = %{"from_user_id" => 1, "to_user_id" => 2, "asset" => "BTC", "amount" => 10}
  state_data_0 = %{ "users" => %{ 1 => %{ "BTC" => %{ "frozen" => 0.0, "available" => 10.0}}}}
  Wallet.deposit(deposit_data_1, state_data)
  #=> %{ "users" => %{ 1 => %{ "BTC" => %{ "frozen" => 0.0, "available" => 20.0}}}}
  """
  def transfer(
        %{
          "from_user_id" => from_user_id,
          "to_user_id" => to_user_id,
          "asset" => asset,
          "amount" => amount
        },
        state_data
      ) do
    with {:ok, _message, new_state_from} <-
           withdraw(
             %{"user_id" => from_user_id, "asset" => asset, "amount" => amount},
             state_data
           ),
         {:ok, _message, new_state_to} <-
           deposit(
             %{"user_id" => to_user_id, "asset" => asset, "amount" => amount},
             new_state_from
           ) do
      {:ok, "Transferred #{amount} #{asset} from user #{from_user_id} to user #{to_user_id}",
       new_state_to}
    else
      {:error, message, response} -> {:error, message, response}
    end
  end

  def revert_operation(state, state_data, "deposit"),
    do: then(withdraw(state, state_data), fn {status, _, state} -> {status, state} end)

  def revert_operation(state, state_data, "withdraw"),
    do: then(deposit(state, state_data), fn {status, _, state} -> {status, state} end)

  def freeze(%{"user_id" => user_id, "asset" => asset, "amount" => amount}, state_data) do
    new_state_data =
      state_data
      |> Map.update!("users", fn users ->
        users
        |> Map.update!(user_id, fn user ->
          user
          |> Map.update!(asset, fn asset ->
            asset
            |> Map.update!("available", fn
              old_available when amount <= old_available -> old_available - amount
              old_available when amount > old_available -> raise "Not Enough Available Balance"
            end)
            |> Map.update!("frozen", fn old_frozen -> old_frozen + amount end)
          end)
        end)
      end)

    {:ok, "Frozen #{amount} #{asset} for user #{user_id}", new_state_data}
  rescue
    _ -> {:error, "Not Enough Available Balance", state_data}
  end

  def unfreeze(%{"user_id" => user_id, "asset" => asset, "amount" => amount}, state_data) do
    new_state_data =
      state_data
      |> Map.update!("users", fn users ->
        users
        |> Map.update!(user_id, fn user ->
          user
          |> Map.update!(asset, fn asset ->
            asset
            |> Map.update!("frozen", fn
              old_frozen when amount <= old_frozen -> old_frozen - amount
              old_frozen when amount > old_frozen -> raise "Not Enough Frozen Balance"
            end)
            |> Map.update!("available", fn old_available -> old_available + amount end)
          end)
        end)
      end)

    {:ok, "Unfrozen #{amount} #{asset} for user #{user_id}", new_state_data}
  rescue
    _ -> {:error, "Not Enough Frozen Balance", state_data}
  end
end

# deposit_data_2 = %{ "user_id" => "2", "asset" => "BTC", "amount" => 10}
# deposit_data_1 = %{"user_id" => 1, "asset" => "BTC", "amount" => 10}
# state_data_0 = %{ "users" => %{ 1 => %{ "BTC" => %{ "frozen" => 0.0, "available" => 10.0}}}}

# TickTakeHome.deposit(deposit_data_2, state_data_0) #deposit para ID nao existente
# TickTakeHome.deposit(deposit_data_1, state_data_0) #deposit para ID existente

# TickTakeHome.withdraw(deposit_data_2, state_data_0) #withdraw para ID nao existente
# TickTakeHome.withdraw(deposit_data_1, state_data_0) #withdraw para ID existente

# usuario possui user_id, asset, frozen e available
# "funcionalidades" => deposit, withdraw, frozen, unfrozen e get balance

# new_data = %{
#  "users" => %{
#    user_id => %{
#      asset => %{
#        "frozen" => 0.0,
#        "available" => available
#      }
#    }
#  }
# }
#  put_in(state_data, [:users, user_id, asset, :available], available)

# Vamos escrever uma funcao que recebe deposit_data e state_data e retorna o novo state_data

# deposit_data_2 = %{
#  "user_id" => 2,
#  "asset" => "BTC",
#  "amount" => 10
# }
# deposit_data_3 = %{
#  "user_id" => "1",
#  "asset" => "BTC",
#  "amount" => 10
# }

#
# state_data_0 = %{
#   "users" => %{
#     1 => %{
#       "BTC" => %{
#         "frozen" => 0.0,
#         "available" => 10.0
#       }
#     }
#   }
# }
# state_data_3 = %{
#   "users" => %{
#     1 => %{
#       "BTC" => %{
#         "frozen" => 0.0,
#         "available" => 10.0
#       }
#     }
#     2 => %{
#       "BTC" => %{
#         "frozen" => 0.0,
#         "available" => 10.0
#       }
#     }
#   }
# }
#
#
#
# deposit_data = %{
#   "user_id" => 1,
#   "asset" => "BTC",
#   "amount" => 10
# }

# state_data_0 = %{
# }

# state_data_1 = %{
#   "users" => %{
#     2 => %{
#       "BTC" => %{
#         "frozen" => 0,
#         "available" => 10
#       }
#     }
#   }
# }
# %{"users" => %{1 => %{"BTC" => %{"frozen" => 0, "available" => 10}}}}

# %{"from_user_id" => 1, "to_user_id" => 2, "asset" => "BTC", "amount" => 10}

# def transfer(%{"from_user_id" => from_user_id, "to_user_id" => to_user_id, "asset" => asset, "amount" => amount}, state_data_from, state_data_to) do
#  with {:ok, _message, new_state_from} <- withdraw(%{"user_id" => from_user_id, "asset" => asset, "amount" => amount}, state_data_from),
#    {:ok, _message, new_state_to} <- deposit(%{"user_id" => to_user_id, "asset" => asset, "amount" => amount}, state_data_to) do
#      {:ok, "Transferred #{amount} #{asset} from user #{from_user_id} to user #{to_user_id}", [new_state_from, new_state_to]}
#    else
#      {:error, message, response} -> {:error, message, response}
#    end
# end
