defmodule TickTakeHome.Models.Operations.Schemas.GeneralOperations do
  use Ecto.Schema
  import Ecto.Changeset
  @required_params [:user_id, :asset, :amount, :operation]
  @allowed_operations ["withdraw", "freeze", "unfreeze"]
  @allowed_assets ["BTC"]

  @derive {Jason.Encoder, only: [:user_id, :asset, :amount, :operation]}
  embedded_schema do
    field :user_id, :integer
    field :asset, :string
    field :amount, :float
    field :operation, :string
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, @required_params)
    |> do_validations(@required_params)
  end

  def do_validations(changeset, fields) do
    changeset
    |> validate_required(fields)
    |> validate_inclusion(:operation, @allowed_operations)
    |> validate_inclusion(:asset, @allowed_assets)
    |> validate_number(:user_id, greater_than: 0)
    |> validate_number(:amount, greater_than: 0)
  end
end
