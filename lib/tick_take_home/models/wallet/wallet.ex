defmodule TickTakeHome.Models.Wallet do
  alias TickTakeHome.Models.Wallet.Repositories.Database

  def insert_wallet do
    Database.insert_wallet()
  end

  def get_wallet(id) do
    Database.get_wallet(id)
  end
end
