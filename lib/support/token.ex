defmodule Token do
  alias Settings, as: S

  def parse(token) do
    case :ejwt.parse_jwt(token, S.jwt_secret) do
      {parsed_token} -> parsed_token
      _ -> :invalid
    end
  end

  def compose(contents, timeout \\ S.expiresIn) do
    :ejwt.jwt("HS256",contents, timeout, S.jwt_secret)
  end

  def extract(token, field) when is_bitstring(token) do
    token |> parse |> get(field)
  end

  def get(parsed_token, field) when is_list(parsed_token) do
    :proplists.get_value(field, parsed_token)
  end

  def update_expiration_time(token, new_timeout \\ S.expiresIn) do
    contents = :lists.map(
      fn({a,b})->
        {binary_to_atom(a),b }; 
      end, parse(token))
    contents = {:proplists.delete(:exp, contents)}
    compose(contents, new_timeout)
  end
end