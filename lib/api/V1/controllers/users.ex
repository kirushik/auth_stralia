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
      User.create(user_id, password)

      #TODO Some special kind of verification token?
      data = %{ sub: user_id,
      #TODO We should introduce hostname setting here
                iss: "auth.example.com",
                jti: "session_id", # TODO
                typ: "user_verification_token"
              }

      send_201(conn, Token.compose(data))
    _ ->
      send_409(conn, "User #{user_id} is already in the database")
    end
  end

  get "verify" do
    conn = fetch_params(conn)
    %{"token" => token} = conn.params

    case Token.parse(token) do

    %{typ: "user_verification_token", sub: user_id} ->
      case User.find_by_uid user_id do
      nil ->
        send_404 conn
      %User{verified: true} ->
        send_409(conn, "User #{user_id} is already verified")
      user ->
        User.verify user
        http_ok(conn, "")
      end

    :expired ->
      send_419 conn

    _ ->
      send_400 conn
    end
  end
end
