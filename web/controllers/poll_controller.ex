defmodule HelloPhoenix.PollController do
  use HelloPhoenix.Web, :controller

  alias HelloPhoenix.Poll

  #http://stackoverflow.com/questions/37596414/are-iconv-convert-return-values-in-wrong-order
  defmodule RailsLikeHelpers do
    require Inflex

    # replace accented chars with their ascii equivalents
    def transliterate_string(abc) do
      :iconv.convert("utf-8", "ascii//translit", String.normalize(abc))
    end

    def parameterize_string(abc) do
      parameterize_string(abc, "_")
    end

    def parameterize_string(abc,seperator) do
      abc
      |> String.strip
      |> transliterate_string
      |> Inflex.parameterize(seperator) # turns "Your Momma" into "your_momma"
      |> String.replace(~r[#{Regex.escape(seperator)}{2,}],seperator)  # No more than one of the separator in a row.
    end
  end

  plug :scrub_params, "poll" when action in [:create, :update]

  def index(conn, _params) do
    polls = Repo.all(Poll)
    render(conn, "index.html", polls: polls)
  end

  def new(conn, _params) do
    changeset = Poll.changeset(%Poll{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"poll" => poll_params}) do
    parameterized = RailsLikeHelpers.parameterize_string(poll_params["url"])
    dict = %{
      :url => parameterized,
      :title => poll_params["title"]
    }

    changeset = Poll.changeset(%Poll{}, dict)

    case Repo.insert(changeset) do
      {:ok, _poll} ->
        conn
        |> put_flash(:info, "Poll created successfully.")
        |> redirect(to: poll_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def vote_here(conn, %{"url" => url}) do
    # http://www.phoenixframework.org/docs/ecto-models
    poll = Repo.get_by!(Poll, url: String.downcase(url))
    #todo: render different template with chat on it
    render(conn, "poll.html", poll: poll)
  end

  def show(conn, %{"id" => id}) do
    poll = Repo.get!(Poll, id)
    render(conn, "show.html", poll: poll)
  end

  def edit(conn, %{"id" => id}) do
    poll = Repo.get!(Poll, id)
    changeset = Poll.changeset(poll)
    render(conn, "edit.html", poll: poll, changeset: changeset)
  end

  def update(conn, %{"id" => id, "poll" => poll_params}) do
    poll = Repo.get!(Poll, id)

    parameterized = RailsLikeHelpers.parameterize_string(poll_params["url"])
    dict = %{
      :url => parameterized,
      :title => poll_params["title"]
    }

    changeset = Poll.changeset(poll, dict)

    case Repo.update(changeset) do
      {:ok, poll} ->
        conn
        |> put_flash(:info, "Poll updated successfully.")
        |> redirect(to: poll_path(conn, :show, poll))
      {:error, changeset} ->
        render(conn, "edit.html", poll: poll, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    poll = Repo.get!(Poll, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(poll)

    conn
    |> put_flash(:info, "Poll deleted successfully.")
    |> redirect(to: poll_path(conn, :index))
  end
end
