defmodule TickTakeHome.Models.Assets.Repositories.Database do
  alias TickTakeHome.Models.Assets.Schema.Asset
  alias TickTakeHome.Repo

  def insert_asset(asset) do
    Repo.insert(Asset.changeset(%Asset{}, %{"id" => asset}))
  end

  def get_asset(id) do
    Repo.get(Asset, id)
  end
end
