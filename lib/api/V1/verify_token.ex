defmodule AuthStralia.API.V1.VerifyToken do
  use Plug.Router

  alias AuthStralia.Redis.Session, as: Session
  alias AuthStralia.Storage.User,  as: User

  import Plug.Conn

  plug :match
  plug :dispatch

  get "/" do
    conn = conn |> fetch_params
    %{"token" => token} = conn.params
    res = case Token.parse(token) do
      :invalid -> "0"
      parsed when is_list(parsed) ->
        Session.check(Token.get(parsed, "sub"), Token.get(parsed, "jti"))
      _ -> "0"
    end
    send_resp(conn, 200, res)
  end
end
