defmodule AuthStralia.Redis.Session do
  use Exredis

  alias Settings, as: S
  alias AuthStralia.Storage.User

  # Key format is 'session:user_id:session_id'
  #TODO: add some useful info (ip?) about session in stored value
  #TODO: connection pool for Redis connections
  def new(user_id, expiration_time \\ S.expiresIn) do
    session_id = UUID.generate

    key = "session:#{user_id}:#{session_id}"
    start |> query ["SETEX", key, expiration_time, "1"]

    data = %{ sub: user_id,
    #TODO We should introduce hostname setting here
              iss: "auth.example.com",
              jti: session_id,
              tags: User.tags(user_id) }
    Token.compose(data)
  end
  def check(user_id, session_id) do
    key = "session:#{user_id}:#{session_id}"
    start |> query ["EXISTS", key]
  end
  def get_ttl(user_id, session_id) do
    key = "session:#{user_id}:#{session_id}"
    start |> query ["TTL", key]
  end
  def list(user_id) do
    key_mask = "session:#{user_id}:*"
    keys = start |> query ["KEYS", key_mask]
    extract_session_ids keys
  end
  def remove(user_id, session_id) do
    key = "session:#{user_id}:#{session_id}"
    start |> query ["DEL", key]
  end
  def remove_all(user_id) do
    key_mask = "session:#{user_id}:*"
    client = start
    keys = client |> query(["KEYS", key_mask])
    client |> query ["DEL" | keys]
  end

  defp extract_session_ids(keys) do
    Enum.map( keys,
              fn(s)->
                String.split(s,":") |> List.last
              end )
  end
end
