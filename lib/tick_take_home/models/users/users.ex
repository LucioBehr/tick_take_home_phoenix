defmodule TickTakeHome.Models.Users do
  alias TickTakeHome.Models.Users.Repositories.Database

  def create_user(wallet_id) do
    Database.create_user(wallet_id)
  end

  def create_user(user_id, wallet_id) do
    Database.create_user(user_id, wallet_id)
  end

  def get_user(id) do
    Database.get_user(id)
  end
end
