defmodule HelloPhoenix.Candidate do
  use HelloPhoenix.Web, :model

  schema "candidates" do
    field :name, :string
    field :created_by, :string
    #has_one?
    belongs_to :poll, HelloPhoenix.Poll, foreign_key: :poll_id
    # field :poll_id, :integer, references(:poll)
    has_many :votes, HelloPhoenix.Vote, on_delete: :delete_all

    timestamps
  end

  @required_fields ~w(name created_by poll)
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
