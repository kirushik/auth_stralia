defmodule AuthStralia.API.V1.UsersController do
  use Plug.Router

  alias AuthStralia.Storage.User,  as: User

  import Plug.Conn
  import AuthStralia.API.V1.Helpers

  plug Plug.Parsers, parsers: [:urlencoded]

  plug :match
  plug :dispatch


  post "new" do
    conn = fetch_params(conn)
    %{"user_id" => user_id, "password" => password} = conn.params

    case User.find_by_uid(user_id) do
    nil ->
      http_ok(conn, "")
    _ ->
      send_409(conn, "User user_id is already in the database")
    end
  end

end
