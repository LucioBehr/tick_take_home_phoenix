defmodule TickTakeHomeWeb.Router do
  use TickTakeHomeWeb, :router
  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TickTakeHomeWeb do
    pipe_through :api
    post "/deposit", TickTakeHomeController, :deposit
    post "/withdraw", TickTakeHomeController, :withdraw
    post "/transfer", TickTakeHomeController, :transfer
    post "/freeze", TickTakeHomeController, :freeze
    post "/unfreeze", TickTakeHomeController, :unfreeze
    # get "/", PageController, :home
  end
end
