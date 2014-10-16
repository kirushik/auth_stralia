defmodule AuthStralia.Router do
  use Plug.Router
  import Plug.Conn


  plug :match
  plug :dispatch

  get "/hello" do
    send_resp(conn, 200, "world")
  end

  match _ do
    send_resp(conn, 404, "oops")
  end
end