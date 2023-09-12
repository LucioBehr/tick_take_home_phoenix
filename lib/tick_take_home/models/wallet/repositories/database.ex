defmodule TickTakeHome.Models.Wallet.Repositories.Database do
  alias TickTakeHome.Models.Wallet.Schema.Wallet
  alias TickTakeHome.Repo

  def insert_wallet do
    Repo.insert(%Wallet{})
  end

  def get_wallet(id) do
    Repo.get(Wallet, id)
  end
end
