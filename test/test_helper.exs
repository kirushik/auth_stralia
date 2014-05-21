Amrita.start

defmodule Localhost do
  alias Settings, as: S

  defmacro __using__(opts) do
    api_version = opts[:version] || 'V1'

    quote bind_quoted: [api_version: api_version] do
      def get(relative_path, headers \\ []) do
        {:ok, {{_,200,_},_,response}} = Localhost.make_get_request(relative_path, unquote(api_version), headers)
        list_to_bitstring response
      end

      def get_http_code(relative_path) do
        {:ok, {{_,code,_},_,_}} = Localhost.make_get_request(relative_path, unquote(api_version))
        code
      end

      def post(relative_path, params \\ %{}, headers \\ []) do
        params = Localhost.params_to_string(params)
        {:ok, {{_,200,_},_,response}} = Localhost.make_post_request(relative_path, unquote(api_version), headers, params)
        list_to_bitstring response
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
    :lists.map(
      fn({a,b}) -> 
        {:ok, b} = List.from_char_data(b);
        {a,b};
      end, headers)  
  end  
end