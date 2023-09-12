defmodule TickTakeHome.Models.Assets.Schema.Asset do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @derive {Phoenix.Param, key: :id}
  schema "assets" do
    field :id, :string, primary_key: true

    has_many :balances, TickTakeHome.Models.Balances.Schema.Balance, references: :id, foreign_key: :asset_id

    timestamps()
  end

  def changeset(asset, params \\ %{}) do
    asset
    |> cast(params, [:id])
    |> validate_required([:id])
  end
end
