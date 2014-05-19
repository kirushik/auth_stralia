defmodule AuthStralia.Caching do
  defmodule Sessions do
    use Exredis

    #TODO Session expiry
    #Maybe use composite (session-user) key for each session object and KEYS query for all operations?
    def add(key, value), do: start |> query ["SADD", key, value]
    def check(key, value), do: start |> query ["SISMEMBER", key, value]
    def list(key), do: start |> query ["SMEMBERS", key]
    def remove(key, value), do: start |> query ["SREM", key, value]
    def remove_all(key), do: start |> query ["DEL", key]
  end
end