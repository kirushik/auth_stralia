defmodule AuthStralia.API.V1.Helpers do
  import Plug.Conn

  def jwt_ok(conn, data) do
    conn |> put_resp_content_type("application/jwt")|>
    send_resp(200, data)
  end

  def http_ok(conn, data)do
    conn |> put_resp_content_type("text/plain")|>
    send_resp(200, data)
  end

  def send_401 conn do
    send_resp(conn, 401, "Authorization failed")
  end
end
