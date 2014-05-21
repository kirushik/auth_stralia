defmodule AuthStralia.Redis do
  defmodule Session do
    use Exredis

    alias Settings, as: S

    # Key format is 'session:user_id:session_id'
    #TODO: — add useful info (ip?) about session in sored value
    def new(user_id, session_id) do
      key = "session:#{user_id}:#{session_id}"
      start |> query ["SETEX", key, S.expiresIn, "1"]
    end
    def check(user_id, session_id) do
      key = "session:#{user_id}:#{session_id}"
      start |> query ["EXISTS", key]
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
      Enum.map(keys, 
                fn(s)-> 
                  String.split(s,":") |> List.last
                end)
    end
  end
end