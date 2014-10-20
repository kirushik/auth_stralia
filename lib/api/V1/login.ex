defmodule AuthStralia.API.V1.LoginController do
  use Plug.Router

  alias AuthStralia.Redis.Session, as: Session
  alias AuthStralia.Storage.User,  as: User

  import Plug.Conn

  plug Plug.Parsers, parsers: [:urlencoded]

  plug :match
  plug :dispatch


  post "/" do
    conn = conn |> fetch_params

    %{"user_id" => user_id, "password" => password} = conn.params

    session_id = UUID.generate

    if (!User.check_password(user_id,password)) do
      send_401 conn
    else
      data = [ sub: user_id,
      #TODO We should introduce hostname setting here
               iss: "auth.example.com",
               jti: session_id,
               tags: User.tags(user_id) ]

      Session.new(user_id, session_id)

      jwt_ok conn, Token.compose(data)
    end
  end

  defp jwt_ok(conn, data) do
    conn |> put_resp_content_type("application/jwt")|>
    send_resp(200, data)
  end

  defp send_401 conn do
    send_resp(conn, 401, "Authorization failed")
  end
end
