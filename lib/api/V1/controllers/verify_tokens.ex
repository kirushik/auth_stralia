defmodule AuthStralia.API.V1.VerifyTokensController do
  use Plug.Router

  alias AuthStralia.Redis.Session, as: Session

  import Plug.Conn
  import AuthStralia.API.V1.Helpers

  plug :match
  plug :dispatch


  get "/" do
    conn = conn |> fetch_params
    %{"token" => token} = conn.params
    res = case Token.parse(token) do
      :invalid -> "0"
      parsed when is_map(parsed) ->
        Session.check(parsed.sub, parsed.jti)
      _ -> "0"
    end
    http_ok(conn, res)
  end
end
