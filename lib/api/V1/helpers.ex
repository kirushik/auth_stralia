defmodule AuthStralia.API.V1.Helpers do
  import Plug.Conn

  def jwt_ok(conn, data) do
    http_ok(conn, data, "application/jwt")
  end

  def json_ok(conn, data) do
    http_ok(conn, data, "application/json")
  end

  def http_ok(conn, data, type \\ "text/plain")do
    conn |> put_resp_content_type(type)|>
    send_resp(200, data)
  end

  def send_401 conn do
    send_resp(conn, 401, "Authorization failed")
  end
end
