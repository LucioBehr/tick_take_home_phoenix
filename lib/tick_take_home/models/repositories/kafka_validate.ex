defmodule TickTakeHome.Models.Repositories.KafkaValidate do
alias TickTakeHome.Models.KafkaMessages.Schema.{KafkaMessage, KafkaDeposit, KafkaTransfer}
  alias TickTakeHome.Models.Repositories.KafkaProducer, as: KafkaProducer

  def validate(message_attrs) do
    message_attrs
    |> get_schema_and_changeset()
    |> handle_changeset_result()
  end

  defp handle_changeset_result({_schema, %Ecto.Changeset{valid?: true} = changeset}) do
    data = Ecto.Changeset.apply_changes(changeset)
    IO.inspect(data)
    KafkaProducer.operation(data)
  end

  defp handle_changeset_result({_schema, changeset}) do
    {:error, changeset.errors}
  end

  defp get_schema_and_changeset(%{operation: "deposit"} = message_attrs) do
    {KafkaDeposit, KafkaDeposit.changeset(%KafkaDeposit{}, message_attrs)}
  end

  defp get_schema_and_changeset(%{operation: "transfer"} = message_attrs) do
    {KafkaTransfer, KafkaTransfer.changeset(%KafkaTransfer{}, message_attrs)}
  end

  defp get_schema_and_changeset(message_attrs) do
    {KafkaMessage, KafkaMessage.changeset(%KafkaMessage{}, message_attrs)}
  end
end

# message_attrs = %{user_id: 1, asset: "BTC", amount: 1.0, operation: "deposit", wallet_id: 5}
# message_attr = %{"user_id" => 1, "asset_id" => "BTC", "amount" => 1.0, "operation" => "deposit", "wallet_id" => 5}
# KafkaValidate.validate(message_attrs)
