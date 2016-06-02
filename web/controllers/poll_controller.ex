defmodule HelloPhoenix.PollController do
  use HelloPhoenix.Web, :controller

  alias HelloPhoenix.Poll

  defmodule MyModule do
    require Inflex
    def parameterize_string(abc) do
      parameterize_string(abc, "_")
    end
    def parameterize_string(abc,seperator) do
      
      abc
      |> String.strip
      |> String.downcase

      result_url =  Enum.map(String.codepoints(abc), fn(x) ->
        if (byte_size(x)>1) do
          :iconv.convert("utf-8", "ascii//translit", x)
          |> String.codepoints()
          |> Enum.at(byte_size(x) - 1)
          #Enum.at(String.codepoints(:iconv.convert "utf-8", "ascii//translit", x),byte_size(x) - 1)
        else
          x
        end
      end)

      result_url
      |> to_string
      |> Inflex.parameterize(seperator)
      |> String.replace(~r[#{seperator}{2,}],seperator)  # No more than one of the separator in a row.

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
    parameterized = MyModule.parameterize_string(poll_params["url"])
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
    render(conn, "show.html", poll: poll)
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
    changeset = Poll.changeset(poll, poll_params)

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
