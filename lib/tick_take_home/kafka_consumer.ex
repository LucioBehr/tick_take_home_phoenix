defmodule TickTakeHome.Models.Repositories.KafkaConsumer do
  @behaviour :brod_group_subscriber

  def init(group_id, _args) do
    IO.puts("Consumer initialized for group: #{group_id}")
    {:ok, nil}
  end

  def start_consumer do
    :brod.start_link_group_subscriber(
      :kafka_client,
      "my_consumer_group",
      ["first"],
      [],
      [],
      TickTakeHome.Models.Repositories.KafkaConsumer,
      []
    )
  end

  def stop_consumer(pid) do
    :brod_group_subscriber.stop(pid)
  end

  def handle_message(
        _topic,
        _partition,
        {:kafka_message, _offset, operation, payload, _headers, _timestamp, _flags},
        state
      ) do
    IO.puts("Received message payload: #{inspect(Jason.decode!(payload))}")
    message = Jason.decode!(payload)

    process_message(message, operation)
    |> IO.inspect()

    {:ok, state}
  end

  # def handle_message(_topic, _partition, message_set, state) do
  #  for {:kafka_message, _, _, _, value, _, _} <- message_set do
  #    IO.puts("Received message list: #{inspect(value)}")
  #  end
  #  {:ok, state}
  # end

  defp process_message(message, operation) do
    # general_message = %{"user_id" => message["user_id_from"], "asset" => message["asset_id"], "amount" => message["amount"]} |> IO.inspect()
    # transfer_message = %{"from_user_id" => message["user_id_from"], "to_user_id" => message["user_id_to"], "asset" => message["asset_id"], "amount" => message["amount"]}

    case operation do
      "deposit" -> TickTakeHome.deposit(message)
      "create_user" -> TickTakeHome.create_user(message["wallet_id"])
      # |> Map.put("wallet_id", message["wallet_id"])
      # |> TickTakeHome.deposit()
      # "withdraw" -> TickTakeHome.withdraw(general_message)
      # "freeze" -> TickTakeHome.freeze(general_message)
      # "unfreeze" -> TickTakeHome.unfreeze(general_message)
      "transfer" -> TickTakeHome.transfer(message)
      _ -> IO.puts("Operation not supported")
    end
  end
end
