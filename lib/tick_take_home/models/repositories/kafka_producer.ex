defmodule TickTakeHome.Models.Repositories.KafkaProducer do
  @client :kafka_client
  @topic "first"
  @partition 0

  def start_client, do: :brod.start_client([{"localhost", 9092}], @client)

  def start_producer, do: :brod.start_producer(@client, @topic, [])

  def create_topic(topic_name, partitions) do
    :brod.create_topics(
      [{"localhost", 9092}],
      [
        %{
          name: topic_name,
          num_partitions: partitions,
          replication_factor: 1,
          assignments: [],
          configs: [%{name: <<"cleanup.policy">>, value: "compact"}]
        }
      ],
      %{timeout: 1000},
      []
    )
  end

  def operation(value) do
    key = value.operation
    value = Jason.encode!(value)
    :brod.produce(@client, @topic, @partition, key, value)
  end
end
