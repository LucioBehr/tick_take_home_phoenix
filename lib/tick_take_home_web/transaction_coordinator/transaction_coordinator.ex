defmodule TickTakeHomeWeb.TransactionCoordinator do
  use GenServer

  alias TickTakeHomeWeb.TransactionCoordinator.Repositories.Store
  alias TickTakeHomeWeb.TransactionCoordinator.Logic
  alias TickTakeHomeWeb.Wallet.Logic, as: WalletLogic

  def start_link(state_data \\ "") do
    GenServer.start_link(__MODULE__, state_data, name: __MODULE__)
  end

  @impl true
  def init(_) do
    {:ok, Store.read_file()}
  end

  def get_state() do
    GenServer.call(__MODULE__, {:get_state})
  end

  def start_transaction(transaction_data) do
    GenServer.call(__MODULE__, {:start_transaction, transaction_data})
  end

  @impl true
  def handle_call({:get_state}, _from, state_data) do
    {:reply, state_data, state_data}
  end

  def handle_call({:start_transaction, transaction_data}, _from, state) do
    %{"transactions_list" => [last_transaction | _]} =
      mid_state =
      Logic.start_transaction(transaction_data, state)
      |> Store.write_file()

    # execute operations:
    operations = Map.get(last_transaction, "operations", [])

    Enum.reduce_while(operations, :ok, fn operation, _acc ->
      case Logic.execute_step(operation, last_transaction["id"]) do
        {:ok, _result} ->
          {:cont, :ok}
        error = {:error, _} ->
          {:halt, error}
      end
    end)
    |> case do
      :ok ->
        mid_state
        |> Logic.finalize_transaction()
        |> Store.write_file()

       _ ->
        # Tell wallets to revert their state if their coordinator_id == last_transaction["id"]
        operations
        |> Enum.map(fn operation ->
          Logic.revert_step(operation, last_transaction["id"])
        end)

        # Finish reverting transaction
        mid_state
        |> Logic.revert_transaction()
        |> Store.write_file()
    end
    |> then(fn state -> {:reply, :ok, state} end)
  end

  @impl true
  def handle_call(
        {:recover_state},
        _from,
        state
      ) do
    last_transaction = List.first(state["transactions_list"])

    case state["last_complete_id"] < last_transaction["id"] do
      true ->
        Enum.each(last_transaction["operations"], fn operation ->
          WalletLogic.revert_operation(state, operation["args"], operation["event"])
        end)
    end

    {:reply, :ok, state}
  end
end
  # %{"asset" => asset, "from_wallet_id" => from_wallet_id, "from_user_id" => from_user_id, "to_wallet_id" => to_wallet_id, "to_user_id" => to_user_id, "amount" => amount} =

################################################################################### 3

### Logica Chrystian
# def transfer_wallet(
#       %{
#         "asset" => asset,
#         "from_wallet_id" => from_wallet_id,
#         "from_user_id" => from_user_id,
#         "to_wallet_id" => to_wallet_id,
#         "to_user_id" => to_user_id,
#         "amount" => amount
#       },
#       state_data_wallet_from,
#       state_data_wallet_to
#     ) do

#   Wallet.transfer( ###
#     %{"from_user_id" => from_user_id, "to_user_id" => to_user_id, "asset" => asset, "amount" => amount},
#     state_data_wallet_from,
#     state_data_wallet_to
#   )
# end

# def coordinator_state(
#      %{"last_complete_id" => last_complete_id, "transactions_list" => transactions_list},
#      state_data_from,
#      state_data_to
#    ) do
#  %{"last_complete_id" => last_complete_id, "transactions_list" => transactions_list}
# end
#
# def status_parser(%{"last_complete_id" => last_complete_id, "transactions_list" => []}), do: %{"last_complete_id" => last_complete_id, "transactions_list" => []}
#
# def status_parser(
#      %{"last_complete_id" => last_complete_id, "transactions_list" => [%{"status" => status}]},
#      %{"coordinator_id" => id},
#      %{"coordinator_id" => id_to}
#    )
#    when id == last_complete_id + 1 and id_to == last_complete_id + 1 do
#  %{"last_complete_id" => last_complete_id, "transactions_list" => [%{"status" => "finished"}]}
# end

#  def transfer_wallet(%{"asset" => asset, "from_wallet_id" => from_wallet_id, "from_user_id" => from_user_id, "to_wallet_id" => to_wallet_id, "to_user_id" => to_user_id, "amount" => amount}, state_data_wallet_from, state_data_wallet_to ) do
#
#  end
#
#  def coordinator_state(last_complete_id, transaction_id, transaction, status) do
#
#  end

# transfer_wallet_data = %{"asset" => "BTC", "from_wallet_id" => 8, "from_user_id" => 1, "to_wallet_id" => 9, "to_user_id" => 1, "amount" => 10}
%{
  "id" => 3,
  "asset" => "ETH",
  "from_wallet_id" => 7,
  "from_user_id" => 1,
  "to_wallet_id" => 8,
  "to_user_id" => 2,
  "amount" => 100,
  "status" => "pending"
}

# C

# Create operations from transaction data
%{
  "operations" => [
    %{
      "event" => :withdraw,
      "process_name" => :wallet_1,
      "args" => %{"asset" => "ETH", "amount" => 100, "user_id" => 1}
    },
    %{
      "event" => :deposit,
      "process_name" => :wallet_2,
      "args" => %{"asset" => "ETH", "amount" => 100, "user_id" => 2}
    }
  ]
}

# Create operations executer
# Create operations REVERTER

coordinator_state = %{
  "last_complete_id" => 2,
  "transactions_list" => [
    %{
      "id" => 3,
      "asset" => "ETH",
      "from_wallet_id" => 1,
      "from_user_id" => 1,
      "to_wallet_id" => 2,
      "to_user_id" => 2,
      "amount" => 100,
      "status" => "pending"
    },
    %{
      "id" => 2,
      "asset" => "ETH",
      "from_wallet_id" => 1,
      "from_user_id" => 1,
      "to_wallet_id" => 2,
      "to_user_id" => 2,
      "amount" => 100,
      "status" => "aborted"
    },
    %{
      "id" => 1,
      "asset" => "ETH",
      "from_wallet_id" => 1,
      "from_user_id" => 2,
      "to_wallet_id" => 2,
      "to_user_id" => 1,
      "amount" => 50,
      "status" => "finished"
    }
  ]
}

# BEGIN
# step 0

#   TickTakeHome.start_link(:wallet_7)
#   TickTakeHome.start_link(:wallet_8)
#   TickTakeHome.TransactionCoordinator.start_link("")
#   a = %{ "asset" => "BTC", "from_wallet_id" => 7,"from_user_id" => 1,"to_wallet_id" => 8,"to_user_id" => 2,"amount" => 10}
#   TickTakeHome.TransactionCoordinator.start_transaction a

coordinator_state = %{
  "last_complete_id" => 0,
  "transactions_list" => []
}

state_data_1 = %{
  "coordinator_id" => 0,
  "users" => %{
    1 => %{
      "ETH" => %{
        "frozen" => 0,
        "available" => 10
      }
    }
  }
}

state_data_2 = %{
  "coordinator_id" => 0,
  "users" => %{
    2 => %{
      "ETH" => %{
        "frozen" => 0,
        "available" => 10
      }
    }
  }
}

# step 1

%{
  "asset" => "ETH",
  "from_wallet_id" => 1,
  "from_user_id" => 1,
  "to_wallet_id" => 2,
  "to_user_id" => 2,
  "amount" => 10
}

# transfer_wallet_data = %{"asset" => "BTC", "from_wallet_id" => 8, "from_user_id" => 1, "to_wallet_id" => 9, "to_user_id" => 1, "amount" => 10}

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
    }
  ]
}

state_data_1 = %{
  "coordinator_id" => 0,
  "users" => %{
    1 => %{
      "ETH" => %{
        "frozen" => 0,
        "available" => 10
      }
    }
  }
}

state_data_2 = %{
  "coordinator_id" => 0,
  "users" => %{
    2 => %{
      "ETH" => %{
        "frozen" => 0,
        "available" => 10
      }
    }
  }
}

# step 2

a = %{
  "asset" => "BTC",
  "from_wallet_id" => 1,
  "from_user_id" => "1",
  "to_wallet_id" => 2,
  "to_user_id" => "2",
  "amount" => 10
}

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
    }
  ]
}

state_data_1 = %{
  "coordinator_id" => 1,
  "users" => %{
    1 => %{
      "ETH" => %{
        "frozen" => 0,
        "available" => 0
      }
    }
  }
}

state_data_2 = %{
  "coordinator_id" => 0,
  "users" => %{
    2 => %{
      "ETH" => %{
        "frozen" => 0,
        "available" => 10
      }
    }
  }
}

# step 3

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
    }
  ]
}

state_data_1 = %{
  "coordinator_id" => 1,
  "users" => %{
    1 => %{
      "ETH" => %{
        "frozen" => 0,
        "available" => 0
      }
    }
  }
}

state_data_2 = %{
  "coordinator_id" => 1,
  "users" => %{
    2 => %{
      "ETH" => %{
        "frozen" => 0,
        "available" => 20
      }
    }
  }
}

# step 4

%{
  "asset" => "ETH",
  "from_wallet_id" => 1,
  "from_user_id" => 1,
  "to_wallet_id" => 2,
  "to_user_id" => 2,
  "amount" => 10
}

coordinator_state = %{
  "last_complete_id" => 1,
  "transactions_list" => [
    %{
      "id" => 1,
      "asset" => "ETH",
      "from_wallet_id" => 1,
      "from_user_id" => 1,
      "to_wallet_id" => 2,
      "to_user_id" => 2,
      "amount" => 10,
      "status" => "finished"
    }
  ]
}

state_data_1 = %{
  "coordinator_id" => 1,
  "users" => %{
    1 => %{
      "ETH" => %{
        "frozen" => 0,
        "available" => 0
      }
    }
  }
}

state_data_2 = %{
  "coordinator_id" => 1,
  "users" => %{
    2 => %{
      "ETH" => %{
        "frozen" => 0,
        "available" => 20
      }
    }
  }
}

# step 2 error recovery

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
    }
  ]
}

state_data_1 = %{
  "coordinator_id" => 0,
  "users" => %{
    1 => %{
      "ETH" => %{
        "frozen" => 0,
        "available" => 10
      }
    }
  }
}

state_data_2 = %{
  "coordinator_id" => 0,
  "users" => %{
    2 => %{
      "ETH" => %{
        "frozen" => 0,
        "available" => 10
      }
    }
  }
}

# step 1 error recovery

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
  "transactions_list" => [
    %{
      "id" => 1,
      "asset" => "ETH",
      "from_wallet_id" => 1,
      "from_user_id" => 1,
      "to_wallet_id" => 2,
      "to_user_id" => 2,
      "amount" => 10,
      "status" => "aborted"
    }
  ]
}

state_data_1 = %{
  "coordinator_id" => 0,
  "users" => %{
    1 => %{
      "ETH" => %{
        "frozen" => 0,
        "available" => 10
      }
    }
  }
}

state_data_2 = %{
  "coordinator_id" => 0,
  "users" => %{
    2 => %{
      "ETH" => %{
        "frozen" => 0,
        "available" => 10
      }
    }
  }
}

x = %{
  "event" => :deposit,
  "process_name" => :wallet_8,
  "args" => %{"asset" => "BTC", "amount" => 5, "user_id" => "1"}
}
