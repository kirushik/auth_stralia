ExUnit.start
Amrita.start

defmodule TokenOperations do
  alias Settings, as: S
  # May be yet another module for this?
  def correct_id, do: "alice@example.com"
  def correct_password, do: "CorrectPassword"
  def tag1, do: "qqq"
  def tag2, do: "Zu Zu Zu"

  # Can be better. Borrowed from EJWT code itself
  def epoch do
    :calendar.datetime_to_gregorian_seconds(:calendar.now_to_universal_time(:os.timestamp())) - 719528 * 24 * 3600
  end
  def generate_token(contents \\ {[ sub: correct_id,
                                    iss: "auth.example.com",
                                    jti: "1282423E-D5EE-11E3-B368-4F7D74EB0A54" ]},
                      timeout \\ 86400) do
    :ejwt.jwt("HS256", contents, timeout, S.jwt_secret)
  end
end

defmodule Localhost do
  alias Settings, as: S

  defmacro __using__(opts) do
    api_version = opts[:version] || 'V1'

    quote bind_quoted: [api_version: api_version] do
      def get(relative_path, headers \\ []) do
        {:ok, {{_,200,_},_,response}} = Localhost.make_get_request(relative_path, unquote(api_version), headers)
        List.to_string response
      end

      def get_http_code(relative_path, headers \\ []) do
        {:ok, {{_,code,_},_,_}} = Localhost.make_get_request(relative_path, unquote(api_version), headers)
        code
      end

      def post(relative_path, params \\ %{}, headers \\ []) do
        params = Localhost.params_to_string(params)
        {:ok, {{_,200,_},_,response}} = Localhost.make_post_request(relative_path, unquote(api_version), headers, params)
        List.to_string response
      end

      def post_http_code(relative_path, params \\ %{}, headers \\ []) do
        params = Localhost.params_to_string(params)
        {:ok, {{_,code,_},_,_}} = Localhost.make_post_request(relative_path, unquote(api_version), headers, params)
        code
      end
    end
  end

  def params_to_string(params) do
    param_strings = for key <- Map.keys(params), do: "#{key}=#{params[key]}"
    Enum.join(param_strings, "&")
  end

  def make_post_request(relative_path, api_version, headers, params) do
    headers = prepare_headers headers
    :httpc.request(
      :post,
      {
        'http://localhost:#{S.port}/api/#{api_version}#{relative_path}',
        headers,
        'application/x-www-form-urlencoded',
        params
      },
      [], [])
  end

  def make_get_request(relative_path, api_version, headers) do
    headers = prepare_headers headers
    :httpc.request(
      :get,
      {
        'http://localhost:#{S.port}/api/#{api_version}#{relative_path}',
        headers
      },
      [], [])
  end

  defp prepare_headers(headers) do
    Enum.map(headers,
      fn({a,b}) ->
        {a, to_char_list(b)}
      end)
  end
end
