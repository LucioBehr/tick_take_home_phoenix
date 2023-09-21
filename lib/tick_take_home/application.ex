defmodule TickTakeHome.Application do
  @moduledoc false
  alias TickTakeHomeWeb.TransactionCoordinator

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TickTakeHome.Repo,
      {Phoenix.PubSub, name: TickTakeHome.PubSub},
      TickTakeHomeWeb.Endpoint,
      TickTakeHome.KafkaConsumer
      # {TickTakeHomeWeb.Wallet, name: :wallet_1},
      # {TickTakeHomeWeb.Wallet, name: :wallet_2},
      # TickTakeHomeWeb.TransactionCoordinator
    ]

    opts = [strategy: :one_for_all, name: TickTakeHome.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    TickTakeHomeWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
