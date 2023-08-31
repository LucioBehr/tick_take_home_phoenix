defmodule TickTakeHome do
  use GenServer
  # use File
  ### comandos para teste
  # TickTakeHome.get_all(:wallet_7) #mostrar
  # TickTakeHome.deposit(:wallet_7, deposit_data) #depositar
  # TickTakeHome.withdraw(:wallet_7, deposit_data) #retirar
  # TickTakeHome.freeze(:wallet_7, deposit_data) #congelar
  # TickTakeHome.unfreeze(:wallet_7, deposit_data) #descongelar

  alias TickTakeHome.Wallet.Logic

  @allowed_operations [
    :deposit,
    :revert_deposit,
    :revert_withdraw,
    :withdraw,
    :transfer,
    :freeze,
    :unfreeze
  ]

  def start_link(name \\ __MODULE__) do
    GenServer.start_link(__MODULE__, name, name: name)
  end

  @impl true
  # state_data
  def init(name), do: {:ok, read_file(name)}

  def read_file(file_name) do
    # unless File.exists?(path), do:
    File.read("state_#{file_name}.json")
    |> case do
      {:ok, content} when content != "" -> Jason.decode!(content)
      _ -> %{"users" => %{}, "name" => file_name, "coordinator_id" => 0}
    end
  end

  def write_file(%{"name" => file_name} = data),
    do: data |> tap(fn data -> File.write!("state_#{file_name}.json", Jason.encode!(data)) end)

  def stop(name), do: GenServer.stop(name)

  def get_all(name), do: GenServer.call(name, {:get_all})

  def transfer(name, arg), do: GenServer.call(name, {:transfer, arg})

  def deposit(name, arg), do: GenServer.call(name, {:deposit, arg})

  def revert_deposit(name, arg), do: GenServer.call(name, {:revert_deposit, arg})

  def revert_withdraw(name, arg), do: GenServer.call(name, {:revert_withdraw, arg})

  def withdraw(name, arg), do: GenServer.call(name, {:withdraw, arg})

  def freeze(name, arg), do: GenServer.call(name, {:freeze, arg})

  def unfreeze(name, arg), do: GenServer.call(name, {:unfreeze, arg})

  @impl true
  def handle_call({:get_all}, _from, state_data), do: {:reply, state_data, state_data}

  @impl true
  def handle_call({operation_name, _} = oper, _from, state_data)
      when operation_name in @allowed_operations,
      do:
        tap(process_persistent_operation(oper, state_data), fn {_, _, state_data} ->
          write_file(state_data)
        end)

  @impl true
  def handle_call({operation_name, args, coordinator_id}, _from, state_data)
      when operation_name in @allowed_operations,
      do:
        tap(process_persistent_operation({operation_name, args}, state_data), fn {_, _,
                                                                                  state_data} ->
          write_file(%{state_data | "coordinator_id" => coordinator_id})
        end)

  @impl true
  def handle_call(_, _from, state_data), do: {:reply, :error, state_data}

  def process_persistent_operation({:deposit, arg}, state_data),
    do:
      then(Logic.deposit(arg, state_data), fn {status, response, state} ->
        {:reply, {status, response}, state}
      end)

  def process_persistent_operation({:revert_deposit, arg}, state_data),
    do: Logic.revert_operation(arg, state_data, :deposit)

  def process_persistent_operation({:revert_withdraw, arg}, state_data),
    do: Logic.revert_operation(arg, state_data, :withdraw)

  def process_persistent_operation({:withdraw, arg}, state_data),
    do:
      then(Logic.withdraw(arg, state_data), fn {status, response, state} ->
        {:reply, {status, response}, state}
      end)

  def process_persistent_operation({:transfer, arg}, state_data),
    do:
      then(Logic.transfer(arg, state_data), fn {status, response, state} ->
        {:reply, {status, response}, state}
      end)

  def process_persistent_operation({:freeze, arg}, state_data),
    do:
      then(Logic.freeze(arg, state_data), fn {status, response, state} ->
        {:reply, {status, response}, state}
      end)

  def process_persistent_operation({:unfreeze, arg}, state_data),
    do:
      then(Logic.unfreeze(arg, state_data), fn {status, response, state} ->
        {:reply, {status, response}, state}
      end)
end

# def transfer(namefrom, nameto, arg) do
#  response = GenServer.call(namefrom, {:withdraw, arg})
#  write(namefrom, response)
#  response = GenServer.call(nameto, {:deposit, arg})
#  write(nameto, response)
# end
# @impl true
# def process_persisten_operation({:transfer, arg}, _from, [state_data_from, state_data_to]) do
#  {_, response, state} = Wallet.transfer(arg, state_data_from, state_data_to)
#  {:reply, response, [state_from, state_to]}
# end
# deposit_data_2 = %{ user_id: 2, asset: "BTC", amount: 10}
# deposit_data_1 = %{user_id: 1, asset: "BTC", amount: 10}
# state_data_0 = %{ users: %{ 1 => %{ "BTC" => %{ frozen: 0.0, available: 10.0}}}}

# TickTakeHome.deposit(deposit_data_2, state_data_0) #deposit para ID nao existente
# TickTakeHome.deposit(deposit_data_1, state_data_0) #deposit para ID existente

# TickTakeHome.withdraw(deposit_data_2, state_data_0) #withdraw para ID nao existente
# TickTakeHome.withdraw(deposit_data_1, state_data_0) #withdraw para ID existente

# usuario possui user_id, asset, frozen e available
# funcionalidades: deposit, withdraw, frozen, unfrozen e get balance

# new_data = %{
#  users: %{
#    user_id => %{
#      asset => %{
#        frozen: 0.0,
#        available: available
#      }
#    }
#  }
# }
#  put_in(state_data, [:users, user_id, asset, :available], available)

# Vamos escrever uma funcao que recebe deposit_data e state_data e retorna o novo state_data

# deposit_data_2 = %{
#  user_id: 1,
#  asset: "BTC",
#  amount: 10
# }
# deposit_data_3 = %{
#   user_id: 2,
#   asset: "ETH",
#   amount: 10
#  }
#
# state_data_0 = %{
#   users: %{
#     1 => %{
#       "BTC" => %{
#         frozen: 0.0,
#         available: 10.0
#       }
#     }
#   }
# }
#
#
#
#
# deposit_data = %{
#   user_id: 1,
#   asset: "BTC",
#   amount: 10
# }
# state_data_0 = %{
# }

# state_data_1 = %{
#   users: %{
#     1 => %{
#       "BTC" => %{
#         frozen: 0,
#         available: 10
#       }
#     }
#   }
# }
# %{users: %{1 => %{"BTC" => %{frozen: 0, available: 10}}}}
