defmodule TickTakeHomeWeb.Wallet do
  use GenServer

  alias TickTakeHomeWeb.Wallet.Logic
  alias TickTakeHomeWeb.Wallet.Repositories.Store


  @allowed_operations [
    :deposit,
    :revert_deposit,
    :revert_withdraw,
    :withdraw,
    :transfer,
    :freeze,
    :unfreeze
  ]

  @revert_operations [
    :revert_deposit,
    :revert_withdraw,
  ]

  def child_spec(opts) do
    name = Keyword.fetch!(opts, :name)
     %{
      id: name,
      start: {__MODULE__, :start_link, [[name: name]]},
      restart: :temporary,
      type: :worker
    }
  end

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, name, id: name, name: name)
  end

  @impl true
  # state_data
  def init(name), do: {:ok, Store.read(name)}

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
          Store.write(state_data)
        end)

  @impl true
  def handle_call({operation_name, args, coordinator_id}, _from, %{"coordinator_id" => wallet_coordinator_id} = state_data) when operation_name in @revert_operations do
    case wallet_coordinator_id == coordinator_id do
      true ->
        tap(process_persistent_operation({operation_name, args}, state_data), fn {_, _, state_data} ->
          Store.write(%{state_data | "coordinator_id" => coordinator_id - 1})
        end)
      false -> {:reply, {:ok, "Already reverted"}, state_data}
    end
  end

  @impl true
  def handle_call({operation_name, args, coordinator_id}, _from, state_data)
      when operation_name in @allowed_operations,
      do:
        tap(process_persistent_operation({operation_name, args}, state_data), fn {_, _,
                                                                                  state_data} ->
          Store.write(%{state_data | "coordinator_id" => coordinator_id})
        end)

  @impl true
  def handle_call(_, _from, state_data), do: {:reply, :error, state_data}

  def process_persistent_operation({:deposit, arg}, state_data),
    do:
      then(Logic.deposit(arg, state_data), fn {_status, response, state} ->
        {:reply, response, state}
      end)

  def process_persistent_operation({:revert_deposit, arg}, state_data),
    do: Logic.revert_operation(arg, state_data, "deposit")

  def process_persistent_operation({:revert_withdraw, arg}, state_data),
    do: Logic.revert_operation(arg, state_data, "withdraw")

  def process_persistent_operation({:withdraw, arg}, state_data),
    do:
      then(Logic.withdraw(arg, state_data), fn {_status, response, state} ->
        {:reply, response, state}
      end)

  def process_persistent_operation({:transfer, arg}, state_data),
    do:
      then(Logic.transfer(arg, state_data), fn {_status, response, state} ->
        {:reply, response, state}
      end)

  def process_persistent_operation({:freeze, arg}, state_data),
    do:
      then(Logic.freeze(arg, state_data), fn {_status, response, state} ->
        {:reply, response, state}
      end)

  def process_persistent_operation({:unfreeze, arg}, state_data),
    do:
      then(Logic.unfreeze(arg, state_data), fn {_status, response, state} ->
        {:reply, response, state}
      end)
end
