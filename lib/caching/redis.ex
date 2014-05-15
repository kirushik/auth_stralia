defmodule AuthStralia.Caching do
  defmodule Sessions do
    use Exredis

    def add(key, value), do: start |> query ["SADD", key, value]
    def check(key, value), do: start |> query ["SISMEMBER", key, value]
    def list(key), do: start |> query ["SMEMBERS", key]
    def remove(key, value), do: start |> query ["SREM", key, value]
  end
end