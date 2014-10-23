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

  def update_expiration_time(token, new_timeout \\ S.expiresIn) do
    contents = parse(token) |> Map.delete(:exp)
    compose(contents, new_timeout)
  end

  # FIXME needs test coverage
  def generate_verification_token(user_id, time_correction \\ 0) do
    if (Mix.env != :test && time_correction != 0), do: Logger.warn "Please use Token.generate_verification_token/2 only in testing!"

    %{ sub: user_id,
        #TODO We should introduce hostname setting here
        iss: "auth.example.com",
        jti: "session_id", # TODO
        typ: "user_verification_token"
      } |> compose(S.expiresIn + time_correction)
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
