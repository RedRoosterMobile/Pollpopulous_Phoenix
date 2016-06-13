defmodule HelloPhoenix.RoomChannel do
  use HelloPhoenix.Web, :channel

  alias HelloPhoenix.Poll
  alias HelloPhoenix.Candidate
  alias HelloPhoenix.Vote
  alias HelloPhoenix.Repo

  def join("rooms:lobby", payload, socket) do
    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # for any other room: todo get room name from url that's
  # been created in db via a specific poll
  # - copy model from Pollpopulous Rails app
  def join("rooms:" <> _room_id_from_url, payload, socket) do
    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (rooms:lobby).
  def handle_in("shout", payload, socket) do
    broadcast socket, "shout", payload
    {:noreply, socket}
  end

  def handle_in("new:message", msg, socket) do
    broadcast! socket, "new:message", %{body: msg["body"], user: msg["user"]}
    {:noreply, socket}
  end

  def handle_in("pp:add_candidate", msg, socket) do
      IO.inspect msg
      IO.puts msg["candidate"]
      IO.puts msg["nickname"]
      IO.puts msg["poll"]
      # IO.inspect (Poll |> Repo.get_by!(url: String.downcase(url)) |> Repo.preload([:candidates]))

      # prevent multiple adds of the same candidate-name for a poll
      if (Candidate |> Repo.get_by(name: msg["candidate"])) do
        IO.puts "candidate does exist already"
        poll = Poll |> Repo.get_by(url: msg["poll"])
        IO.puts poll.id
        unless(poll) do
          IO.puts "poll not found"
        end
      else
        IO.puts "candidate does not exist yet"
        poll = Poll |> Repo.get_by(url: msg["poll"])
        unless(poll) do
          IO.puts "poll not found"
        end
        poll_id = poll.id
        unless(poll_id) do
          IO.puts "poll_id not found"
        end
        IO.puts poll_id
        # ------

        # http://stackoverflow.com/questions/36254866/insert-ecto-model-with-already-existing-model-as-an-association
        # http://stackoverflow.com/questions/30584276/mixing-scopes-and-associations-in-phoenix-ecto
        # https://blog.drewolson.org/composable-queries-ecto/
        # ** (ArgumentError) unknown field `poll`
        # (note only fields, embedded models, has_one and has_many
        # associations are supported in cast)
        # http://blog.plataformatec.com.br/2015/08/working-with-ecto-associations-and-embeds/
        # http://www.phoenixframework.org/docs/ecto-models
        # plain old insert:
        # INSERT INTO Candidates (created_by,name,poll_id) VALUES (msg["nickname"],msg["candidate"],poll_id);
        # https://hexdocs.pm/ecto/Ecto.Changeset.html

        changeset = %Candidate{
          created_by: msg["nickname"],
          name: msg["candidate"],
          poll_id: poll_id
        }
        IO.puts "got here after changeset!!!"
        IO.inspect changeset

        case Repo.insert(changeset) do
          {:ok, candidate} ->
            IO.puts("success saving")
            IO.inspect candidate
            # send event to frontend attributes of last candidate
            broadcast! socket, "new:candidate", %{
              created_by: candidate.created_by,
              name: candidate.name,
              poll_id: poll_id,
              id: candidate.id
            }
          {:error, changeset} ->
            IO.puts("failed saving")
        end
      end

      # annalytics: https://github.com/stueccles/analytics-elixir/

      # get all candidates
      #candidates = @poll.candidates.push(Candidate.new(name: message[:name]))

      #poll = Poll |> Repo.get!(1)
      ##IO.inspect(poll)

      broadcast! socket, "new:message", %{body: msg["candidate"], user: msg["nickname"]}
      #IO.inspect poll
      {:noreply, socket}
  end

  def handle_in("pp:vote_for_candidate", msg, socket) do
      # msg["nickname"]
      msg["candidate"]
      # msg["poll_name"]

# http://stackoverflow.com/questions/33710272/preload-all-relationships
      candi = (
        Candidate
        |> Repo.get_by(name: msg["candidate"])
        |> Repo.preload([:poll])
        #|> Repo.preload([:votes]) 
      )
      if candi do
        IO.puts "candidate found"
        IO.inspect candi
      else
        IO.puts "candidate not found"
      end
      #if (Vote |> Repo.get_by(name: msg["candidate"])) do
      #end
      {:noreply, socket}
  end

  #def handle_in("pp:revoke_vote", payload, socket) do end

  #def handle_in("pp:vote_for_candidate", payload, socket) do end

  # This is invoked every time a notification is being broadcast
  # to the client. The default implementation is just to push it
  # downstream but one could filter or change the event.
  def handle_out(event, payload, socket) do
    push socket, event, payload
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
