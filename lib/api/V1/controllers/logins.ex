defmodule AuthStralia.API.V1.LoginsController do
  use Plug.Router

  alias AuthStralia.Redis.Session
  alias AuthStralia.Storage.User

  import Plug.Conn
  import AuthStralia.API.V1.Helpers

  plug Plug.Parsers, parsers: [:urlencoded]

  plug :match
  plug :dispatch


  post "/" do
    conn = conn |> fetch_params
    %{"user_id" => user_id, "password" => password} = conn.params

    if User.check_password(user_id,password) do

      jwt_ok(conn, Session.new(user_id))
    else
      send_401 conn
    end
  end
end
