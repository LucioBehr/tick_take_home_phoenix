defmodule TickTakeHomeWeb.TickTakeHomeController do
  use TickTakeHomeWeb, :controller

  alias TickTakeHome, as: Server
  alias TickTakeHome.Models.Repositories.KafkaValidate

  # write the TickTakeHome controller using TickTakeHome as basis, only using their functions
  def create_user(conn, %{"wallet_id" => wallet_id}) do
    case KafkaValidate.validate(%{wallet_id: wallet_id, operation: "create_user"}) do
      {:error, error} -> send_resp(conn, 400, error)
      _ -> send_resp(conn, 200, "user created")
    end
  end

end
