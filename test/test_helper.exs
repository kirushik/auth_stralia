Amrita.start

defmodule Localhost do
  defmacro __using__(opts) do
    api_version = opts[:version] || 'V1'

    quote bind_quoted: [api_version: api_version] do
      def get(relative_path) do
        {:ok, {{_,200,_},_,response}} = :httpc.request('http://localhost:3000/api/'++ unquote(api_version) ++ relative_path)
        list_to_bitstring response
      end

      def post(relative_path, params) do
        params_string = Localhost.params_to_string(params)
        {:ok, {{_,200,_},_,response}} = Localhost.make_post_request(relative_path, unquote(api_version), params_string)
        list_to_bitstring response
      end

      def post_http_code(relative_path, params) do
        params = Localhost.params_to_string(params)
        {:ok, {{_,code,_},_,_}} = Localhost.make_post_request(relative_path, unquote(api_version), params)
        code
      end
    end
  end

  def params_to_string(params) do
    param_strings = for key <- Map.keys(params), do: "#{key}=#{params[key]}"
    Enum.join(param_strings, "&")
  end

  def make_post_request(relative_path, api_version, params) do
    :httpc.request(
      :post, 
      { 'http://localhost:3000/api/'++ api_version ++ relative_path, 
        [], 
        'application/x-www-form-urlencoded',
        params},
      [], [])
  end
end