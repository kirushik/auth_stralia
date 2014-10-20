defmodule AuthStralia.API.V1.SessionController do
  use Plug.Router

  alias AuthStralia.Redis.Session, as: Session
  alias AuthStralia.Storage.User,  as: User

  import Plug.Conn

  plug Plug.Parsers, parsers: [:urlencoded]

  plug :match
  plug :dispatch


  post "invalidate" do
    conn = conn |> fetch_params
    case get_req_header(conn, "bearer") do
    [token] ->
      jti = if Dict.has_key?(conn.params, :jti) do
        conn.params.jti
      else
        Token.extract(token, "jti")
      end
      sub = Token.extract(token, "sub")

      http_ok(conn, Session.remove(sub, jti))
    [] ->
      send_401 conn
    end
  end

    post "invalidate/all" do
      case get_req_header(conn, "bearer") do
      [token] ->
        sub = Token.extract(token, "sub")
        http_ok(conn, Session.remove_all(sub))
      [] ->
        send_401 conn
      end
    end

    get "list" do
      case get_req_header(conn, "bearer") do
      [token] ->
        sub = Token.extract(token, "sub")
        http_ok(conn, JSON.encode!(Session.list(sub)))
      [] ->
        send_401 conn
      end
    end

    post "update" do
      case get_req_header(conn, "bearer") do
      [token] ->
        http_ok(conn, Token.update_expiration_time(token))
      [] ->
        send_401 conn
      end
    end

  defp http_ok(conn, data)do
    send_resp(conn, 200, data)
  end

  defp send_401(conn) do
    send_resp(conn, 401, "Unauthorized")
  end
end