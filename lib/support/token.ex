require Logger

defmodule Token do
  alias Settings, as: S

  def parse(token) do
    case :ejwt.parse_jwt(token, S.jwt_secret) do
      {parsed_token} -> proplist_to_map(parsed_token)
      :expired -> :expired
      _ -> :invalid
    end
  end

  def parse(token, :force) do
    [_, claims_raw, _]= String.split(token, ".")
    {:ok, claims} = claims_raw |> :base64url.decode |> JSON.decode
    claims |> proplist_to_map
  end

  def compose(contents, timeout \\ S.expiresIn) do
    :ejwt.jwt("HS256",{Map.to_list contents}, timeout, S.jwt_secret)
  end

  def extract(token, field) when is_bitstring(token) do
    token |> parse |> Map.get(field)
  end

  def update_expiration_time(token, new_expiration_time \\ S.expiresIn) do
    case parse(token) do
    :expired ->
      parse(token, :force)
    claims ->
      claims
    end |>
    Map.delete(:exp) |>
    compose(new_expiration_time)
  end

  def generate_verification_token(user_id, session_id, expiration_time \\ S.expiresIn) do
    %{ sub: user_id,
        #TODO We should introduce hostname setting here
        iss: "auth.example.com",
        jti: session_id,
        typ: "user_verification_token"
      } |> compose(expiration_time)
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
