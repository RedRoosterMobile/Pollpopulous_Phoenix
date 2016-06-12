defmodule HelloPhoenix.Vote do
  use HelloPhoenix.Web, :model

  schema "votes" do
    field :nickname, :string
    belongs_to :poll, HelloPhoenix.Poll
    belongs_to :candidate, HelloPhoenix.Candidate

    timestamps
  end

  @required_fields ~w(nickname)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end
