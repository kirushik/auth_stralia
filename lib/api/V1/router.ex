defmodule AuthStralia.API.V1.Router do
  use Plug.Router
  use Plug.Builder

  import Plug.Conn
  import AuthStralia.API.V1.Helpers

  plug :enable_cors
  plug :verify_token_presence, %{paths: ["session"]}

  plug :match
  plug :dispatch

  # Enabling CORS on all the endpoints
  options _ do
    conn |>
    put_resp_header("access-control-allow-origin", "*") |>
    put_resp_header("access-control-allow-methods", "GET, OPTIONS, POST") |>
    put_resp_header("access-control-allow-headers", "AUTHORIZATION, CONTENT-TYPE") |>
    http_ok ""
  end

  forward "login", to: AuthStralia.API.V1.LoginController
  forward "verify_token", to: AuthStralia.API.V1.VerifyTokenController
  forward "session", to: AuthStralia.API.V1.SessionController

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

  defp enable_cors(conn, _opts) do
    put_resp_header(conn, "access-control-allow-origin", "*")
  end

end
