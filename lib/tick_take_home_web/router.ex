defmodule TickTakeHomeWeb.Router do
  use TickTakeHomeWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TickTakeHomeWeb do
    pipe_through :api
    post "/deposit", WalletController, :deposit
    post "/withdraw", WalletController, :withdraw
    post "/transfer", WalletController, :transfer
    post "/freeze", WalletController, :freeze
    post "/unfreeze", WalletController, :unfreeze
    post "/revert_deposit", WalletController, :revert_deposit
    post "/revert_withdraw", WalletController, :revert_withdraw
    get "/get_all", WalletController, :get_all

    post "/start_transaction", TransactionCoordinatorController, :start_transaction
    get "/get_state", TransactionCoordinatorController, :get_state
    # get "/", PageController, :home
  end
end
