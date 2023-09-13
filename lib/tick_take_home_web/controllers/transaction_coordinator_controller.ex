defmodule TickTakeHomeWeb.TransactionCoordinatorController do
  use TickTakeHomeWeb, :controller

  alias TickTakeHomeWeb.TransactionCoordinator

  def start_transaction(conn, params) do
    response =
      TransactionCoordinator.start_transaction(params)
      |> Jason.encode!()

    send_resp(conn, 200, response)
  end

  def get_state(conn, _params) do
    response =
      TransactionCoordinator.get_state()
      |> Jason.encode!()

    send_resp(conn, 200, response)
  end
end
