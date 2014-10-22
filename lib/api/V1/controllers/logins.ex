defmodule AuthStralia.API.V1.LoginsController do
  use Plug.Router

  alias AuthStralia.Redis.Session, as: Session
  alias AuthStralia.Storage.User,  as: User

  import Plug.Conn
  import AuthStralia.API.V1.Helpers

  plug Plug.Parsers, parsers: [:urlencoded]

  plug :match
  plug :dispatch


  post "/" do
    conn = conn |> fetch_params
    %{"user_id" => user_id, "password" => password} = conn.params


    if (!User.check_password(user_id,password)) do
      send_401 conn
    else
      session_id = UUID.generate
      data = %{ sub: user_id,
      #TODO We should introduce hostname setting here
                iss: "auth.example.com",
                jti: session_id,
                tags: User.tags(user_id) }

      Session.new(user_id, session_id)

      jwt_ok conn, Token.compose(data)
    end
  end
end
