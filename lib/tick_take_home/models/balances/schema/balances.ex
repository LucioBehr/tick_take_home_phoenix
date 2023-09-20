defmodule TickTakeHome.Models.Balances.Schema.Balance do
  use Ecto.Schema
  import Ecto.Changeset

  # @primary_key {:id, :binary_id, autogenerate: true}
  schema "balances" do
    field :available, :float, default: 0.0
    field :frozen, :float, default: 0.0

    belongs_to :user, TickTakeHome.Models.Users.Schema.User
    belongs_to :asset, TickTakeHome.Models.Assets.Schema.Asset, type: :string
    timestamps()
  end

  def changeset(balance, params \\ %{}) do
    balance
    |> cast(params, [:available, :frozen, :user_id, :asset_id])
    |> validate_required([:user_id, :asset_id])
    |> foreign_key_constraint(:user_id, name: "balances_user_id_fkey")
    |> foreign_key_constraint(:asset_id, name: "balances_asset_id_fkey")
  end

  def fields(), do: __schema__(:fields)
end
