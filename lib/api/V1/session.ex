defmodule AuthStralia.API.V1.SessionController do
  use Plug.Router

  alias AuthStralia.Redis.Session, as: Session
  alias AuthStralia.Storage.User,  as: User

  import Plug.Conn

  plug :match
  plug :dispatch

  match _ do
    send_resp(conn, 300, "QQQ")
  end

end
