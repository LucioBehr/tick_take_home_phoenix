defmodule TickTakeHome.Repo do
  use Ecto.Repo,
    otp_app: :tick_take_home,
    adapter: Ecto.Adapters.Postgres
end
