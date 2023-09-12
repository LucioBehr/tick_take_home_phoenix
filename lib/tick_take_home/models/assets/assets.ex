defmodule TickTakeHome.Models.Assets do
  alias TickTakeHome.Models.Assets.Repositories.Database

  def insert_asset(asset) do
    Database.insert_asset(asset)
  end

  def get_asset(id) do
    Database.get_asset(id)
  end
end
