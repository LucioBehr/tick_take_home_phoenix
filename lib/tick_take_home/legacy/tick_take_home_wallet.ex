# defmodule TickTakeHomeWeb.Wallet.Logic do
#   alias TickTakeHome.Repo
#   import Ecto.Query

#   # alias TickTakeHomeWeb.Wallet.Logic
#   # Logic.deposit(%{"user_id" => 9, "asset" => "BTC", "amount" => 10})

#   @moduledoc """
#   This module deals with the logic behind internal wallet operations,
#   such as deposit, withdraw, freeze, unfreeze, and transfers between users within the same wallet.
#   """

#   @doc """
#   Deposits a specific amount of an asset for a user.
#   The function accepts a map containing `user_id`, `asset`, and `amount` as keys.
#   It updates the available quantity of that asset for the user in the given state.

#   ## Parameters
#     - `params`: A map with the following keys:
#       - `"user_id"`: The user's ID.
#       - `"asset"`: The type of asset being deposited.
#       - `"amount"`: The amount of the asset to be deposited.
#     - `state_data`: The current state containing user data.

#   ## Returns
#     - `{:ok, message, new_state_data}`: If the deposit was successful.
#     - `:ok`: An atom indicating success.
#     - A string message detailing the deposit made.
#     - The `new_state_data`, which is the updated state after the deposit.

#   ## Example usage:
#   deposit_data_1 = %{"user_id" => 1, "asset" => "BTC", "amount" => 10}
#   state_data_0 = %{ "users" => %{ 1 => %{ "BTC" => %{ "frozen" => 0.0, "available" => 10.0}}}}
#   Wallet.deposit(deposit_data_1, state_data)
#   #=> %{ "users" => %{ 1 => %{ "BTC" => %{ "frozen" => 0.0, "available" => 20.0}}}}
#   """

#   # def validate_datas(%{user_id: user_id, wallet_id: wallet_id, asset: asset}) do
#   #   case {Repo.get(Assets, asset), Repo.get(Users, user_id), Repo.get(Wallets, wallet_id)} do
#   #     {nil, _, _} -> {:error, :error, :error} # asset nao existe
#   #     {_, _, nil} -> {:error, :error, :error} # wallet nao existe
#   #     {_, nil, _} -> {:ok, :error, :ok}   # usuario nao existe
#   #     _ -> {:ok, :ok, :ok} # tudo ok
#   #   end
#   # end

#   # def deposit(%{"user_id" => user_id, "asset" => asset, "amount" => amount, "wallet_id" => wallet_id}) do
#   #   balance = Repo.one(from b in Balances, where: b.user_id == ^user_id and b.asset_id == ^asset)
#   #   case validate_datas(%{user_id: user_id, wallet_id: wallet_id, asset: asset}) do
#   #     {:ok, :error, :ok} ->
#   #       Repo.insert!(Users.changeset(%Users{}, %{"id" => user_id, "wallet_id" => wallet_id}))
#   #       if balance do
#   #         Repo.update(Balances.changeset(balance, %{available: balance.available + amount}))
#   #       else
#   #         Repo.insert!(Balances.changeset(%Balances{}, %{"user_id" => user_id, "asset_id" => asset, "available" => amount, "frozen" => 0.0}))
#   #       end
#   #       {:ok, "Deposited #{amount} #{asset} for user #{user_id}"}
#   #     {:ok, :ok, :ok} ->
#   #       if balance do
#   #         Repo.update(Balances.changeset(balance, %{available: balance.available + amount}))
#   #       else
#   #         Repo.insert!(Balances.changeset(%Balances{}, %{"user_id" => user_id, "asset_id" => asset, "available" => amount, "frozen" => 0.0}))
#   #       end
#   #       {:ok, "Deposited #{amount} #{asset} for user #{user_id}"}
#   #     {:error, :error, :error} -> {:error, "Invalid Params"}
#   #   end
#   # end



#   def validate_datas(%{user_id: user_id, wallet_id: wallet_id, asset: asset}) do
#     case {Repo.get(Assets, asset), Repo.get(Users, user_id), Repo.get(Wallets, wallet_id)} do
#       {nil, _, _} -> {:error, :missing_asset}
#       {_, _, nil} -> {:error, :missing_wallet}
#       {_, nil, _} -> {:error, :missing_user}
#       _ -> :ok # tudo ok
#     end
#   end

#   def deposit(%{"user_id" => user_id, "asset" => asset, "amount" => amount, "wallet_id" => wallet_id}) do
#     case {validate_datas(%{user_id: user_id, wallet_id: wallet_id, asset: asset}), Repo.one(from b in Balances, where: b.user_id == ^user_id and b.asset_id == ^asset)} do
#       {{:error, :missing_asset}, _balance} -> {:error, "Invalid Asset"}
#       {{:error, :missing_wallet}, _balance} -> {:error, "Invalid Wallet"}
#       {{:error, :missing_user}, _balance} ->
#         Repo.insert!(Users.changeset(%Users{}, %{"id" => user_id, "wallet_id" => wallet_id}))
#         Repo.insert!(Balances.changeset(%Balances{}, %{"user_id" => user_id, "asset_id" => asset, "available" => amount, "frozen" => 0.0}))
#         {:ok, "Deposited #{amount} #{asset} for user #{user_id}"}
#       {:ok, balance} when not is_nil(balance) ->
#         Repo.update(Balances.changeset(balance, %{available: balance.available + amount}))
#         {:ok, "Deposited #{amount} #{asset} for user #{user_id}"}
#       {:ok, _balance} ->
#         Repo.insert!(Balances.changeset(%Balances{}, %{"user_id" => user_id, "asset_id" => asset, "available" => amount, "frozen" => 0.0}))
#         {:ok, "Deposited #{amount} #{asset} for user #{user_id}"}
#     end
#   end

#   def withdraw(%{"user_id" => user_id, "asset" => asset, "amount" => amount, "wallet_id" => wallet_id}) do
#     balance = Repo.one(from b in Balances, where: b.user_id == ^user_id and b.asset_id == ^asset and b.available >= ^amount)
#     case validate_datas(%{user_id: user_id, wallet_id: wallet_id, asset: asset}) do
#       {:error, _} -> {:error, "Invalid Params"}
#       :ok ->
#         if balance do
#           Repo.update(Balances.changeset(balance, %{available: balance.available - amount}))
#           {:ok, "Withdrawn #{amount} #{asset} for user #{user_id}"}
#         else
#           {:error, "Not enough balance"}
#         end

#     end
#   end

#   def freeze(%{"user_id" => user_id, "asset" => asset, "amount" => amount, "wallet_id" => wallet_id}) do
#     balance = Repo.one(from b in Balances, where: b.user_id == ^user_id and b.asset_id == ^asset and b.available >= ^amount)
#     case validate_datas(%{user_id: user_id, wallet_id: wallet_id, asset: asset}) do
#       {:error, _} -> {:error, "Invalid Params"}
#       :ok ->
#         if balance do
#           Repo.update(Balances.changeset(balance, %{available: balance.available - amount, frozen: balance.frozen + amount}))
#           {:ok, "Frozen #{amount} #{asset} for user #{user_id}"}
#         else
#           {:error, "Not enough balance"}
#         end

#     end
#   end

#   def unfreeze(%{"user_id" => user_id, "asset" => asset, "amount" => amount, "wallet_id" => wallet_id}) do
#     balance = Repo.one(from b in Balances, where: b.user_id == ^user_id and b.asset_id == ^asset and b.frozen >= ^amount)
#     case validate_datas(%{user_id: user_id, wallet_id: wallet_id, asset: asset}) do
#       {:error, _} -> {:error, "Invalid Params"}
#       :ok ->
#         if balance do
#           Repo.update(Balances.changeset(balance, %{available: balance.available + amount, frozen: balance.frozen - amount}))
#           {:ok, "Unfrozen #{amount} #{asset} for user #{user_id}"}
#         else
#           {:error, "Not enough frozen balance"}
#         end

#     end
#   end

#   def transfer(%{"from_user_id" => from_user_id, "to_user_id" => to_user_id, "asset" => asset, "amount" => amount, "wallet_id" => wallet_id}) do
#     balance_from = Repo.one(from b in Balances, where: b.user_id == ^from_user_id and b.asset_id == ^asset and b.available >= ^amount)
#     #balance_to = Repo.one(from b in Balances, where: b.user_id == ^to_user_id and b.asset_id == ^asset)
#     case validate_datas(%{user_id: from_user_id, wallet_id: wallet_id, asset: asset}) do
#       {:error, _} -> {:error, "Invalid Params"}
#       :ok ->
#         if balance_from do
#           withdraw(%{"user_id" => from_user_id, "asset" => asset, "amount" => amount, "wallet_id" => wallet_id})
#           deposit(%{"user_id" => to_user_id, "asset" => asset, "amount" => amount, "wallet_id" => wallet_id})
#           {:ok, "Transferred #{amount} #{asset} from user #{from_user_id} to user #{to_user_id}"}
#         else
#           {:error, "Not enough balance"}
#         end

#     end
#   end



#   #Repo.insert!(Balances.changeset(%Balances{}, %{"user_id" => user_id, "asset_id" => asset, "available" => amount}))

#   def get() do
#     #Repo.insert(%Wallets{})
#     #Repo.insert(Users.changeset(%Users{}, %{"id" => 9, "wallet_id" => 5}))
#     Repo.all(Balances)
#     Repo.all(Assets)
#     #Repo.delete_all(Users)
#     #Repo.delete_all(Wallets)
#     #Repo.delete_all(Balances)
#     Repo.all(Users)
#     Repo.all(Wallets)
#   end

#   def queimaessaporra() do
#     Repo.delete_all(Users)
#     Repo.delete_all(Wallets)
#     Repo.delete_all(Balances)
#     Repo.delete_all(Assets)
#   end

#   def vsfd() do
#     #Repo.insert(%Wallets{})
#     #Repo.insert(Assets.changeset(%Assets{}, %{"id" => "BTC"}))
#     #Repo.insert(Users.changeset(%Users{}, %{"id" => 4, "wallet_id" => 3}))
#     #Repo.insert(Balances.changeset(%Balances{}, %{"user_id" => 3, "asset_id" => "BTC", "available" => 10, "frozen" => 0}))
#     deposit(%{"user_id" => 4, "asset" => "BTC", "amount" => 10, "wallet_id" => 3})
#   end

#   #########################################
#   # def freeze(%{"user_id" => user_id, "asset" => asset, "amount" => amount}) do
#   #   with %Assets{} <- Repo.get(Assets, asset),
#   #         %Users{} <- Repo.get(Users, user_id),
#   #         %Balances{} = balance <- Repo.get(Balances, {user_id, asset}) do
#   #     case Repo.get(Balances, {user_id, asset}) do
#   #       balance ->
#   #         if balance.available >= amount do
#   #           case Repo.update!(Balances, where: [user_id: user_id, asset_id: asset], set: [available: balance.available - amount, frozen: balance.frozen + amount]) do
#   #             {:ok, _response} -> {:ok, "Frozen #{amount} #{asset} for user #{user_id}"}
#   #           end
#   #         end
#   #       nil -> {:error, "Not Enough Balance"}
#   #     end
#   #   else
#   #     nil -> {:error, "Not Enough Balance"}
#   #   end
#   # end
# nd
#  # def unfreeze(%{"user_id" => user_id, "asset" => asset, "amount" => amount}) do
#  #   with {:ok, _response} <- Repo.get(Assets, asset),
#  #         {:ok, _response} <- Repo.get(Users, user_id),
#  #         {:ok, _response} <- Repo.get(Balances, {user_id, asset}),
#  #         {:ok, _response} <- Repo.update!(Balances, where: [user_id: user_id, asset_id: asset], set: [frozen: Balances.frozen + amount]) do
#  #           {:ok, "Frozen #{amount} #{asset} for user #{user_id}"}
#  #   else
#  #     {:error, _response} -> {:error, "Not Enough Balance"}
#  #   end
#  # end
#    #case Repo.get(Assets, asset) do
#    #  {:ok, _response} ->
#    #    case Repo.get(Users, user_id) do
#    #      {:ok, _response} ->
#    #        case Repo.get(Balances, {user_id, asset}) do
#    #          {:ok, _response} ->
#  #def withdraw(%{"user_id" => user_id, "asset" => asset, "amount" => amount}, state_data) do
#  #  new_state_data =
#  #    state_data
#  #    |> Map.update!("users", fn users ->
#  #      users
#  #      |> Map.update!(user_id, fn user ->
#  #        user
#  #        |> Map.update!(asset, fn asset ->
#  #          asset
#  #          |> Map.update!("available", fn
#  #            old_available when amount <= old_available -> old_available - amount
#  #            old_available when amount > old_available -> raise "Not Enough Balance"
#  #          end)
#  #        end)
#  #      end)
#  #    end)

#  #  {:ok, "Withdrawn #{amount} #{asset} for user #{user_id}", new_state_data}
#  #rescue
#  #  _ -> {:error, "Not Enough Balance", state_data}
#  #end
#   def transfer(
#         %{
#           "from_user_id" => from_user_id,
#           "to_user_id" => to_user_id,
#           "asset" => asset,
#           "amount" => amount
#         },
#         state_data
#       ) do
#     with {:ok, _message, new_state_from} <-
#            withdraw(
#              %{"user_id" => from_user_id, "asset" => asset, "amount" => amount},
#              state_data
#            ),
#          {:ok, _message, new_state_to} <-
#            deposit(
#              %{"user_id" => to_user_id, "asset" => asset, "amount" => amount},
#              new_state_from
#            ) do
#       {:ok, "Transferred #{amount} #{asset} from user #{from_user_id} to user #{to_user_id}",
#        new_state_to}
#     else
#       {:error, message, response} -> {:error, message, response}
#     end
#   end

#   def revert_operation(state, state_data, "deposit"),
#     do: then(withdraw(state, state_data), fn {status, _, state} -> {status, state} end)

#   def revert_operation(state, state_data, "withdraw"),
#     do: then(deposit(state, state_data), fn {status, _, state} -> {status, state} end)

#   def freeze(%{"user_id" => user_id, "asset" => asset, "amount" => amount}, state_data) do
#     new_state_data =
#       state_data
#       |> Map.update!("users", fn users ->
#         users
#         |> Map.update!(user_id, fn user ->
#           user
#           |> Map.update!(asset, fn asset ->
#             asset
#             |> Map.update!("available", fn
#               old_available when amount <= old_available -> old_available - amount
#               old_available when amount > old_available -> raise "Not Enough Available Balance"
#             end)
#             |> Map.update!("frozen", fn old_frozen -> old_frozen + amount end)
#           end)
#         end)
#       end)

#     {:ok, "Frozen #{amount} #{asset} for user #{user_id}", new_state_data}
#   rescue
#     _ -> {:error, "Not Enough Available Balance", state_data}
#   end

#   def unfreeze(%{"user_id" => user_id, "asset" => asset, "amount" => amount}, state_data) do
#     new_state_data =
#       state_data
#       |> Map.update!("users", fn users ->
#         users
#         |> Map.update!(user_id, fn user ->
#           user
#           |> Map.update!(asset, fn asset ->
#             asset
#             |> Map.update!("frozen", fn
#               old_frozen when amount <= old_frozen -> old_frozen - amount
#               old_frozen when amount > old_frozen -> raise "Not Enough Frozen Balance"
#             end)
#             |> Map.update!("available", fn old_available -> old_available + amount end)
#           end)
#         end)
#       end)

#     {:ok, "Unfrozen #{amount} #{asset} for user #{user_id}", new_state_data}
#   rescue
#     _ -> {:error, "Not Enough Frozen Balance", state_data}
#   end
# end

# # deposit_data_2 = %{ "user_id" => "2", "asset" => "BTC", "amount" => 10}
# # deposit_data_1 = %{"user_id" => 1, "asset" => "BTC", "amount" => 10}
# # state_data_0 = %{ "users" => %{ 1 => %{ "BTC" => %{ "frozen" => 0.0, "available" => 10.0}}}}

# # TickTakeHome.deposit(deposit_data_2, state_data_0) #deposit para ID nao existente
# # TickTakeHome.deposit(deposit_data_1, state_data_0) #deposit para ID existente

# # TickTakeHome.withdraw(deposit_data_2, state_data_0) #withdraw para ID nao existente
# # TickTakeHome.withdraw(deposit_data_1, state_data_0) #withdraw para ID existente

# # usuario possui user_id, asset, frozen e available
#  "funcionalidades" => deposit, withdraw, frozen, unfrozen e get balance
#  new_data = %{
#   "users" => %{
#     user_id => %{
#       asset => %{
#         "frozen" => 0.0,
#         "available" => available
#       }
#     }
#   }
#  }
#   put_in(state_data, [:users, user_id, asset, :available], available)
#  Vamos escrever uma funcao que recebe deposit_data e state_data e retorna o novo state_data
#  deposit_data_2 = %{
#   "user_id" => 2,
#   "asset" => "BTC",
#   "amount" => 10
#  }
#  deposit_data_3 = %{
#   "user_id" => "1",
#   "asset" => "BTC",
#   "amount" => 10
#  }

#  state_data_0 = %{
#    "users" => %{
#      1 => %{
#        "BTC" => %{
#          "frozen" => 0.0,
#          "available" => 10.0
#        }
#      }
#    }
#  }
#  state_data_3 = %{
#    "users" => %{
#      1 => %{
#        "BTC" => %{
#          "frozen" => 0.0,
#          "available" => 10.0
#        }
#      }
#      2 => %{
#        "BTC" => %{
#          "frozen" => 0.0,
#          "available" => 10.0
#        }
#      }
#    }
#  }



#  deposit_data = %{
#    "user_id" => 1,
#    "asset" => "BTC",
#    "amount" => 10
#  }
#  state_data_0 = %{
#  }
#  state_data_1 = %{
#    "users" => %{
#      2 => %{
#        "BTC" => %{
#          "frozen" => 0,
#          "available" => 10
#        }
#      }
#    }
#  }
#  %{"users" => %{1 => %{"BTC" => %{"frozen" => 0, "available" => 10}}}}
#  %{"from_user_id" => 1, "to_user_id" => 2, "asset" => "BTC", "amount" => 10}
#  def transfer(%{"from_user_id" => from_user_id, "to_user_id" => to_user_id, "asset" => asset, "amount" => amount}, state_data_from, state_data_to) do
#   with {:ok, _message, new_state_from} <- withdraw(%{"user_id" => from_user_id, "asset" => asset, "amount" => amount}, state_data_from),
#     {:ok, _message, new_state_to} <- deposit(%{"user_id" => to_user_id, "asset" => asset, "amount" => amount}, state_data_to) do
#       {:ok, "Transferred #{amount} #{asset} from user #{from_user_id} to user #{to_user_id}", [new_state_from, new_state_to]}
#     else
#       {:error, message, response} -> {:error, message, response}
#     end
#  end
