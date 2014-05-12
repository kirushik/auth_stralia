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
        param_strings = for key <- Map.keys(params), do: "#{key}=#{params[key]}"
        param_string = Enum.join(param_strings, "&")

        {:ok, {{_,200,_},_,response}} = :httpc.request(
          :post, 
          { 'http://localhost:3000/api/'++ unquote(api_version) ++ relative_path, 
            [], 
            'application/x-www-form-urlencoded',
            param_string},
          [], [])
        list_to_bitstring response
      end
    end
  end
end