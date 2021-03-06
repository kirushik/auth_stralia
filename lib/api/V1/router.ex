defmodule AuthStralia.API.V1.Router do
  use Plug.Router
  use Plug.Builder

  import Plug.Conn
  import AuthStralia.API.V1.Helpers

  plug :enable_cors
  plug :verify_token_presence, %{paths: ["session"]}

  plug :match
  plug :dispatch

  options _ do
    http_ok(conn, "")
  end

  forward "login", to: AuthStralia.API.V1.LoginsController
  forward "user", to: AuthStralia.API.V1.UsersController
  forward "verify_token", to: AuthStralia.API.V1.VerifyTokensController
  forward "session", to: AuthStralia.API.V1.SessionsController

  defp enable_cors(conn, _opts) do
    conn |>
    put_resp_header("access-control-allow-origin", "http://localhost:9000") |>
    put_resp_header("access-control-allow-methods", "GET, OPTIONS, POST") |>
    put_resp_header("access-control-allow-credentials", "true") |>
    put_resp_header("access-control-expose-headers", "authorization")|>
    put_resp_header("access-control-allow-headers", "accept, authorization, content-type, origin, x-requested-with")
  end

  defp verify_token_presence(conn, %{paths: paths}) do
    if List.first(conn.path_info) in paths do
      case get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        conn |> put_private(:token, token)
      _ ->
        send_401 conn |> halt
      end
    else
      conn
    end
  end

end
