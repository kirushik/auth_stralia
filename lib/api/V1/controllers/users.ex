defmodule AuthStralia.API.V1.UsersController do
  use Plug.Router

  alias AuthStralia.Storage.User
  alias AuthStralia.Redis.VerificationSession
  alias AuthStralia.Redis.Session

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
      token = User.verification_token_for user_id
      send_201(conn, token)
    _ ->
      send_409(conn, "User #{user_id} is already in the database")
    end
  end

  get "verify" do
    conn = fetch_params(conn)
    %{"token" => token} = conn.params

    case Token.parse(token) do

    %{typ: "user_verification_token", sub: user_id, jti: verification_session_id} ->
      case User.find_by_uid user_id do
      nil ->
        send_404 conn
      %User{verified: true} ->
        send_409(conn, "User #{user_id} is already verified")
      user ->
        if VerificationSession.check(user_id, verification_session_id) do
          User.verify user
          VerificationSession.delete user_id
          jwt_ok(conn, Session.new(user_id))
        else
          send_419 conn
        end
      end

    :expired ->
      send_419 conn

    _ ->
      send_400 conn
    end
  end

  get "proof_token" do
    conn = fetch_params(conn)
    %{"user_id" => user_id} = conn.params

    case User.find_by_uid user_id do
    %User{verified: true} ->
      send_403 conn
    %User{verified: false} ->
      http_ok conn, User.verification_token_for user_id
    nil ->
      send_404 conn
    end

  end
end
