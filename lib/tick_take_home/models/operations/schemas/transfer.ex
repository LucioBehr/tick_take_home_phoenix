defmodule TickTakeHome.Models.Operations.Schemas.Transfer do
  use Ecto.Schema
  import Ecto.Changeset
  @required_params [:from_user_id, :to_user_id, :asset, :amount]
  @allowed_assets ["BTC"]

  @derive {Jason.Encoder, only: [:from_user_id, :to_user_id, :asset, :amount, :operation]}
  embedded_schema do
    field :from_user_id, :integer
    field :to_user_id, :integer
    field :asset, :string
    field :amount, :float
    field :operation, :string, default: "transfer"
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, @required_params)
    |> do_validations(@required_params)
  end

  def do_validations(changeset, fields) do
    changeset
    |> validate_required(fields)
    |> validate_inclusion(:asset, @allowed_assets)
    |> validate_number(:from_user_id, greater_than: 0)
    |> validate_number(:to_user_id, greater_than: 0)
    |> validate_number(:amount, greater_than: 0)
  end
end
