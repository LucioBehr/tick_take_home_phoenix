defmodule TickTakeHomeWeb.Wallet.Repositories.Store do
  def read(name) do
    # unless File.exists?(path), do:
    File.read("state_#{name}.json")
    |> case do
      {:ok, content} when content != "" -> Jason.decode!(content)
      _ -> %{"users" => %{}, "name" => name, "coordinator_id" => 0}
    end
  end

  def write(%{"name" => name} = data),
    do: data |> tap(fn data -> File.write!("state_#{name}.json", Jason.encode!(data)) end)
end
