defmodule HelloPhoenix.Poll do
  use HelloPhoenix.Web, :model

  schema "polls" do
    field :title, :string
    field :url, :string
    has_many :candidates, HelloPhoenix.Candidate, on_delete: :delete_all
    has_many :votes, HelloPhoenix.Vote
    timestamps
  end

  @required_fields ~w(title url)
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
