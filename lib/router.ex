defmodule AuthStralia.Router do
  use Plug.Router

  import Plug.Conn

  plug :match
  plug :dispatch

  forward "/api/V1", to: AuthStralia.API.V1.Router

  match _ do
    send_resp(conn, 404, "oops")
  end
end
