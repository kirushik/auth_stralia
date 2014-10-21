defmodule AuthStralia.API.V1.SessionController do
  use Plug.Router

  alias AuthStralia.Redis.Session, as: Session
  # alias AuthStralia.Storage.User,  as: User

  import Plug.Conn
  import AuthStralia.API.V1.Helpers

  plug Plug.Parsers, parsers: [:urlencoded]

  plug :match
  plug :dispatch

  post "invalidate" do
    conn = conn |> fetch_params
    [token] = get_req_header(conn, "bearer")
    jti = if Dict.has_key?(conn.params, :jti) do
      conn.params.jti
    else
      Token.extract(token, "jti")
    end
    sub = Token.extract(token, "sub")

    http_ok(conn, Session.remove(sub, jti))
  end

  post "invalidate/all" do
    [token] = get_req_header(conn, "bearer")
    sub = Token.extract(token, "sub")
    http_ok(conn, Session.remove_all(sub))
  end

  get "list" do
    [token] = get_req_header(conn, "bearer")
    sub = Token.extract(token, "sub")
    json_ok(conn, JSON.encode!(Session.list(sub)))
  end

  post "update" do
    [token] = get_req_header(conn, "bearer")
    jwt_ok(conn, Token.update_expiration_time(token))
  end
end
