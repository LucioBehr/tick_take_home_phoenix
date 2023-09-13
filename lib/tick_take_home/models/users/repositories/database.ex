defmodule TickTakeHome.Models.Users.Repositories.Database do
  alias TickTakeHome.Models.Users.Schema.User
  alias TickTakeHome.Repo
  import Ecto.Query
  # create, get

  def create_user(wallet_id) do
    Repo.insert(User.changeset(%User{}, %{"wallet_id" => wallet_id}))
  end

  def create_user(user_id, wallet_id) do
    Repo.insert(User.changeset(%User{}, %{"id" => user_id, "wallet_id" => wallet_id}))
  end

  def get_user(id) do
    Repo.get(User, id)
  end
end
