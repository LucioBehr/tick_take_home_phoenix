defmodule TickTakeHome.Models.Operations do
  alias TickTakeHome.Models.Operations.Schemas.{GeneralOperations, Deposit, Transfer}
  alias TickTakeHome.Models.Repositories.KafkaProducer, as: KafkaProducer

  # for create_user
  def start_operation(%{wallet_id: wallet_id, operation: "create_user"} = message_attrs) do
    case is_integer(wallet_id) do
      true -> KafkaProducer.operation(message_attrs)
      false -> {:error, "wallet_id must be an integer"}
    end
  end

  # for deposit, transfer, withdraw, freeze, unfreeze
  def start_operation(message_attrs) do
    message_attrs
    |> get_schema_and_changeset()
    |> handle_changeset_result()
  end

  defp handle_changeset_result(%Ecto.Changeset{valid?: true} = changeset) do
    data = Ecto.Changeset.apply_changes(changeset)
    IO.inspect(data)
    KafkaProducer.operation(data)
  end

  defp handle_changeset_result(changeset) do
    {:error, changeset.errors}
  end

  defp get_schema_and_changeset(%{operation: "deposit"} = message_attrs) do
    Deposit.changeset(%Deposit{}, message_attrs)
  end

  defp get_schema_and_changeset(%{operation: "transfer"} = message_attrs) do
    Transfer.changeset(%Transfer{}, message_attrs)
  end

  defp get_schema_and_changeset(message_attrs) do
    GeneralOperations.changeset(%GeneralOperations{}, message_attrs)
  end
end

# message_attrs = %{user_id: 1, asset: "BTC", amount: 1.0, operation: "deposit", wallet_id: 5}
# message_attr = %{"user_id" => 1, "asset_id" => "BTC", "amount" => 1.0, "operation" => "deposit", "wallet_id" => 5}
# KafkaValidate.validate(message_attrs)
