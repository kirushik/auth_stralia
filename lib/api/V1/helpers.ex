defmodule AuthStralia.API.V1.Helpers do
  import Plug.Conn

  def jwt_ok(conn, data) do
    http_ok(conn, data, "application/jwt")
  end

  def json_ok(conn, data) do
    http_ok(conn, data, "application/json")
  end

  def http_ok(conn, data, type \\ "text/plain")do
    put_resp_content_type(conn, type) |>
    send_resp(200, data)
  end

  def send_201(conn, data) do
    send_resp(conn, 201, data)
  end

  def send_400 conn do
    send_resp(conn, 400, "Unable to parse the token provided")
  end

  def send_401 conn do
    send_resp(conn, 401, "Authorization failed")
  end

  def send_404 conn do
    send_resp(conn, 404, "Not found")
  end

  def send_409(conn, data) do
    send_resp(conn, 409, data)
  end
end
