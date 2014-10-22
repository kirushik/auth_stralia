defmodule Token do
  alias Settings, as: S

  def parse(token) do
    case :ejwt.parse_jwt(token, S.jwt_secret) do
      {parsed_token} -> proplist_to_map(parsed_token)
      :expired -> :expired
      _ -> :invalid
    end
  end

  def compose(contents, timeout \\ S.expiresIn) do
    :ejwt.jwt("HS256",{Map.to_list contents}, timeout, S.jwt_secret)
  end

  def extract(token, field) when is_bitstring(token) do
    token |> parse |> Map.get(field)
  end

  def update_expiration_time(token, new_timeout \\ S.expiresIn) do
    contents = parse(token) |> Map.delete(:exp)
    compose(contents, new_timeout)
  end

  defp proplist_to_map(proplist) do
    proplist |>
    Enum.map(
      fn( {a,b}) ->
        { String.to_atom(a), b };
      end) |>
    Enum.into %{}
  end
end
