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
    # prevent multiple adds of the same candidate-name for a poll
    if (Candidate |> Repo.get_by(name: msg["name"])) do
      IO.puts "candidate does exist already"
      {:reply, {:error, %{message: "candidate does exist already"}}, socket}
    else
      IO.puts "candidate does not exist yet"
      poll = Poll |> Repo.get_by(id: msg["poll_id"])
      poll_id = poll.id

      changeset = %Candidate{
        created_by: msg["nickname"],
        name: msg["name"],
        poll_id: poll_id
      }
      IO.puts "got here after changeset!!!"
      IO.inspect changeset

      case Repo.insert(changeset) do
        {:ok, candidate} ->
          IO.puts("success saving")
          IO.inspect candidate
          # send event to frontend attributes of last candidate
          broadcast! socket, "new_candidate", %{
            created_by: candidate.created_by,
            name: candidate.name,
            poll_id: poll_id,
            id: candidate.id,
            votes: []
          }
          {:reply, {:ok, %{message: "saved candidate"}}, socket}
          {:error, changeset} ->
            IO.puts("failed saving")
            {:reply, {:error, %{message: "failed saving"}}, socket}
          end
        end
      end

      def handle_in("pp:vote_for_candidate", msg, socket) do
        IO.inspect msg

        # http://stackoverflow.com/questions/33710272/preload-all-relationships
        candi = (
        Candidate
        |> Repo.get_by(id: msg["candidate_id"])
        |> Repo.preload([:poll])
        |> Repo.preload([:votes])
        )
        # if else fucked up!!!!!
        if candi do
          IO.puts "candidate found"
          IO.inspect candi
          vote = Vote
          |> Repo.get_by(
            nickname: msg["nickname"],
            poll_id: candi.poll.id
          )
          IO.puts "vote:"
          IO.inspect vote

          if vote do
            IO.puts "you've already voted for this poll"
            {:reply, {:error, %{message: "you've already voted for this poll"}}, socket}
            #{:reply, {:error, %{message: "you've already voted for this poll"}}, socket}
            #{:error, %{reason: "you've already voted for this poll"} }
          else
            IO.puts "no vote found for candidate"
            # create vote on poll
            changeset = %Vote{
              nickname: msg["nickname"],
              candidate_id: msg["candidate_id"],
              poll_id: candi.poll.id
            }
            IO.inspect changeset


            #changeset = Vote.changeset(%Vote{}, dict)

            case Repo.insert(changeset) do
              {:ok, new_vote} ->
                IO.puts "vote added"
                IO.inspect new_vote
                # return candidate-id + vote
                broadcast! socket, "new_vote", %{
                  candidate_id: msg["candidate_id"],
                  vote: %{
                    poll_id: candi.poll.id,
                    id: new_vote.id,
                    nickname: new_vote.nickname,
                  }
                }
                {:reply, {:ok, %{message: "vote added"}}, socket}
                {:error, changeset} ->
                  {:error, %{reason: "could not add to db"}}
                  unless vote do
                    {:reply, {:error, %{message: "could not add to db"}}, socket}
                  end
                end
                # candidate_id = message[:candidate_id]
                # @new_vote = Vote.new(poll_id: @poll.id, candidate_id: candidate_id, nickname: message[:nickname])

                # trigger_success(message: @new_vote.save)

                # trigger update of all channel members
                # WebsocketRails[@poll.url.to_sym].trigger(:new_vote, {candidate_id: candidate_id, vote: @new_vote})
              end

              # check
            else
              IO.puts "candidate not found"
              {:error, %{reason: "candidate not found"}}
              {:reply, {:error, %{message: "candidate not found"}}, socket}
            end
            #if (Vote |> Repo.get_by(name: msg["candidate"])) do
            #end
            #{:noreply, socket}
          end

          def handle_in("pp:revoke_vote", msg, socket) do
            msg["nickname"]
            msg["vote_id"]
            msg["candidate_id"]
            vote = Vote
            |> Repo.get_by(
            id: msg["vote_id"],
            nickname: msg["nickname"],
            candidate_id: msg["candidate_id"]
            )
            if vote do
              Repo.delete!(vote)
              broadcast! socket, "revoked_vote", %{
                candidate_id: msg["candidate_id"],
                vote: %{
                  id: msg["vote_id"],
                  nickname: msg["nickname"],
                  candidate_id: msg["candidate_id"]
                }
              }
              {:reply, {:ok, %{message: "vote deleted"}}, socket}
            else
              {:reply, {:error, %{message: "not your vote"}}, socket}
            end
          end

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
