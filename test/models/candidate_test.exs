defmodule HelloPhoenix.CandidateTest do
  use HelloPhoenix.ModelCase

  alias HelloPhoenix.Candidate

  @valid_attrs %{created_by: "some content", name: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Candidate.changeset(%Candidate{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Candidate.changeset(%Candidate{}, @invalid_attrs)
    refute changeset.valid?
  end
end
