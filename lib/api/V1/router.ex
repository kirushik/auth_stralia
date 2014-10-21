defmodule AuthStralia.API.V1.Router do
  use Plug.Router
  use Plug.Builder

  import Plug.Conn
  import AuthStralia.API.V1.Helpers

  plug :verify_token_presence, %{paths: ["session"]}

  plug :match
  plug :dispatch


  forward "login", to: AuthStralia.API.V1.LoginController
  forward "verify_token", to: AuthStralia.API.V1.VerifyTokenController
  forward "session", to: AuthStralia.API.V1.SessionController

  defp verify_token_presence(conn, %{paths: paths}) do
    if List.first(conn.path_info) in paths do
      case get_req_header(conn, "bearer") do
      [token] ->
        conn
      _ ->
        send_401 conn |> halt
      end
    else
      conn
    end
  end

end
